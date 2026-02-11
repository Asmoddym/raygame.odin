package ui

import "core:fmt"
import "core:slice"
import "../bounding_box"
import "../engine"
import "../engine/error"
import "../globals"
import "core:strings"
import "core:time"
import rl "vendor:raylib"

// Init a text box, generating and storing the metadata to the component pointer
//
// owner_id can point to an int in which the id will be stored for external checks.
// when deleting the textbox, owner_id will be reset to 0.
//
// keep_alive_until_false can point to a bool which will be check on update system to force the box NOT to be deleted.
// when the value is true, the box will stay instanciated.
text_box_draw :: proc(text: string,
                         font_size: i32,
                         attached_to_bounding_box: ^bounding_box.Component_BoundingBox,
                         duration: f64 = -1,
                         owner_id: ^int = nil,
                         keep_alive_until_false: ^bool = nil,
                         color: rl.Color = rl.WHITE) {
  text_box: TextBoxMetadata
  @(static) counter := 0

  counter += 1

  text_box.id = counter
  text_box.owner_id = owner_id
  text_box.keep_alive_until_false = keep_alive_until_false
  text_box.duration = duration
  text_box.instanciated_at = time.now()
  text_box.attached_to_bounding_box = &attached_to_bounding_box.box

  text_box_generate_metadata(&text_box, text, font_size, color)

  text_box.animation_ended = false
  text_box.animated = false
  text_box.ticks = 0

  append(&text_boxes, text_box)

  fmt.println("Created textbox", counter, "(", text, ")")

  if owner_id != nil do owner_id^ = counter
}

// Draw a simple text box without storing anything. Works nice for little texts.
text_box_draw_fast :: proc(text: string, x, y: i32, font_size: i32, color: rl.Color = rl.WHITE) {
  text_box: TextBoxMetadata

  text_box_generate_metadata(&text_box, text, font_size, color)
  text_box_draw_from_metadata(&text_box, { x, y })
}

// Init an animated text box, generating and storing the metadata to the component pointer.
//
// Params are the same as text_box_draw, check for more info.
animated_text_box_draw :: proc(text: string,
                                  font_size: i32,
                                  attached_to_bounding_box: ^bounding_box.Component_BoundingBox,
                                  duration: f64 = -1,
                                  owner_id: ^int = nil,
                                  keep_alive_until_false: ^bool = nil,
                                  color: rl.Color = rl.WHITE) {
  text_box_draw(text, font_size, attached_to_bounding_box, duration, owner_id, keep_alive_until_false, color)

  text_boxes[len(text_boxes) - 1].animated = true
}

// Delete a text_box from its ID.
// If owner_id is not nil, will be reset to 0.
text_box_delete :: proc(id: int) {
  context.user_index = id
  index, found := slice.linear_search_proc(text_boxes[:], proc(md: TextBoxMetadata) -> bool { return md.id == context.user_index })

  if !found do error.raise("textbox", id, "not found")

  text_box := text_boxes[index]
  fmt.println("Deleted textbox", id, "(", text_box.text, "), owner_id:", text_box.owner_id)

  if text_boxes[index].owner_id != nil do text_boxes[index].owner_id^ = 0

  unordered_remove(&text_boxes, index)
}



//
// SYSTEMS
//



// Draw text boxes
system_text_box_draw :: proc() {
  for &item in text_boxes {
    box := item.attached_to_bounding_box

    if box != nil {
      position := [2]i32 { i32(box.x + box.width), i32(box.y) - item.box_height }

      text_box_draw_from_metadata(&item, position)
    }
  }
}

// Update animated text boxes and remove text boxes whose duration is expired
system_text_box_update :: proc() {
  to_delete: [dynamic]int

  for idx in 0..<len(text_boxes) {
    item        := &text_boxes[idx]
    time_source := item.instanciated_at

    if item.animated {
      if item.animation_ended {
        time_source = item.animation_ended_at
      } else {
        if item.ticks < item.text_len {
          time_diff := time.duration_milliseconds(time.diff(item.instanciated_at, time.now()))
          item.ticks = int(time_diff / 30)

          if item.ticks == item.text_len {
            item.animation_ended = true
            item.animation_ended_at = time.now()
          }

          item.words = strings.split(item.text[:item.ticks], " ")
        }
      }
    }

    if item.duration == -1 do continue

    time_diff := time.duration_milliseconds(time.diff(time_source, time.now()))
    if (item.keep_alive_until_false == nil || !item.keep_alive_until_false^) && time_diff > item.duration {
      append(&to_delete, item.id)
    }
  }

  for id in to_delete {
    text_box_delete(id)
  }
}

// // Misc system to keep the camera position to the center of the screen
// system_update_camera_position :: proc() {
//   box := engine.database_get_component(globals.player_id, &bounding_box.layers[globals.PLAYER_LAYER_ID]).box
//
//   engine.camera.target = rl.Vector2 { f32(box.x), f32(box.y) }
// }



//
// PRIVATE
//



@(private="file")
TEXT_PADDING: i32 = 10

@(private="file")
TEXT_WIDTH_THRESHOLD: i32 = 200


// TextBox metadata containing all infos to draw it
@(private="file")
TextBoxMetadata :: struct {
  id: int,
  owner_id: ^int,
  keep_alive_until_false: ^bool,

  lines: i32,
  text_width: i32,
  box_width: i32,
  text_height: i32,
  box_height: i32,

  words_position: [dynamic][2]i32,
  words: []string,
  text: string,
  text_len: int,
  font_size: i32,
  color: rl.Color,

  duration: f64,
  instanciated_at: time.Time,

  animation_ended: bool,
  animation_ended_at: time.Time,

  attached_to_bounding_box: ^rl.Rectangle,
  animated: bool,
  ticks: int,
}

// TextBox storage
@(private="file")
text_boxes: [dynamic]TextBoxMetadata


@(private="file")
text_box_draw_from_metadata :: proc(metadata: ^TextBoxMetadata, position: [2]i32) {
  bytes: [256]byte
  builder := strings.builder_from_bytes(bytes[:])

  rl.DrawRectangle(position.x, position.y, metadata.box_width, metadata.box_height, rl.BLACK)
  rl.DrawRectangleLines(position.x, position.y, metadata.box_width, metadata.box_height, rl.WHITE)

  for i: int = 0; i < len(metadata.words); i += 1 {
    strings.write_string(&builder, metadata.words[i])
    cword := strings.to_cstring(&builder)

    word_position := metadata.words_position[i]
    rl.DrawText(cword, word_position.x + position.x + TEXT_PADDING, word_position.y + position.y + TEXT_PADDING, metadata.font_size, metadata.color)

    strings.builder_reset(&builder)
  }
}

@(private="file")
text_box_generate_metadata :: proc(metadata: ^TextBoxMetadata, text: string, font_size: i32, color: rl.Color) {
  bytes: [256]byte
  builder := strings.builder_from_bytes(bytes[:])
  current_width: i32 = 0

  metadata.text = text
  metadata.text_len = len(text)
  metadata.font_size = font_size
  metadata.words = strings.split(metadata.text, " ")

  for word in metadata.words {
    strings.write_string(&builder, word)

    cword := strings.to_cstring(&builder)
    size := rl.MeasureText(cword, font_size)

    if metadata.text_width < current_width {
      metadata.text_width = current_width
    }

    if current_width > TEXT_WIDTH_THRESHOLD {
      metadata.lines += 1
      current_width = 0
    }

    append(&metadata.words_position, [2]i32 { current_width, metadata.lines * font_size })

    current_width += size + TEXT_PADDING

    strings.builder_reset(&builder)
  }

  if metadata.text_width < current_width {
    metadata.text_width = current_width
  }

  metadata.text_height = (metadata.lines + 1) * font_size
  metadata.box_height = metadata.text_height + (TEXT_PADDING * 2)
  metadata.box_width = metadata.text_width + (TEXT_PADDING * 2)
  metadata.color = color
}
