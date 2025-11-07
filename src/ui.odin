package macro

import "engine"
import "globals"
import "core:strings"
import "core:time"
import rl "vendor:raylib"


// BUTTON


// Draw a list of buttons centered on y and x from engine.game_state.resolution
ui_button_draw_xy_centered_list :: proc(texts: []string, font_size: i32, on_click: []proc(), selected: int = -1, color: rl.Color = rl.WHITE) {
  padding := i32(font_size / 3)
  text_height_with_padding := font_size + 2 * padding

  // Add each text with padding and spacing
  block_height := i32(len(texts)) * text_height_with_padding + (i32(len(texts) - 1) * BUTTON_SPACING)

  // The calculation is made from the text, not the box. We have to remove the padding for the first iteration
  beginning_y := engine.game_state.resolution.y / 2 - block_height / 2 + i32(padding)

  for idx in 0..<len(texts) {
    text := texts[idx]
    measured_text := rl.MeasureText(strings.unsafe_string_to_cstring(text), font_size)
    position := rl.Vector2 {
      f32(engine.game_state.resolution.x / 2 - measured_text / 2),
      f32(beginning_y),
    }

    ui_button_draw(text, position, font_size, on_click[idx], selected == idx, color)
    beginning_y += text_height_with_padding + BUTTON_SPACING
  }
}

// Draw a button with a given size and position
ui_button_draw :: proc(text: string, position: rl.Vector2, font_size: i32, on_click: proc(), selected: bool, color: rl.Color = rl.WHITE) {
  padding := i32(font_size / 3)
  thickness: f32 = 2

  color := color
  ctext := strings.unsafe_string_to_cstring(text)
  measured_text := rl.MeasureText(ctext, font_size)

  width: f32 = f32(measured_text + 2 * padding)
  height: f32 = f32(font_size + 2 * padding)
  box := rl.Rectangle { f32(position.x - f32(padding)), f32(position.y - f32(padding)), width, height }

  if selected {
    thickness = 6

    if rl.IsKeyPressed(.ENTER) do on_click()
  } else {
    color.a /= 2
  }

  rl.DrawText(ctext, i32(position.x), i32(position.y), font_size, color)
  rl.DrawRectangleLinesEx(box, thickness, color)
}


// TEXT BOX


// Init a text box, generating and storing the metadata to the component pointer
ui_text_box_draw :: proc(text: string, font_size: i32, attached_to_bounding_box: ^Component_BoundingBox, duration: f64 = -1, color: rl.Color = rl.WHITE) {
  text_box: TextBoxMetadata

  text_box.duration = duration
  text_box.instanciated_at = time.now()
  text_box.attached_to_bounding_box = &attached_to_bounding_box.box

  ui_text_box_generate_metadata(&text_box, text, font_size, color)

  text_box.animation_ended = false
  text_box.animated = false
  text_box.ticks = 0

  append(&text_boxes, text_box)
}

// Init an animated text box, generating and storing the metadata to the component pointer
ui_animated_text_box_draw :: proc(text: string, font_size: i32, attached_to_bounding_box: ^Component_BoundingBox, duration: f64 = -1, color: rl.Color = rl.WHITE) {
  ui_text_box_draw(text, font_size, attached_to_bounding_box, duration, color)

  text_boxes[len(text_boxes) - 1].animated = true
}



//
// SYSTEMS
//



// Draw text boxes
ui_system_text_box_draw :: proc() {
  for &item in text_boxes {
    box := item.attached_to_bounding_box

    if box != nil {
      position := [2]i32 { i32(box.x + box.width), i32(box.y) - item.box_height }

      // Update animated textbox displayed characters
      if item.animated do item.words = strings.split(item.text[:item.ticks], " ")

      ui_text_box_draw_from_metadata(&item, position)
    }
  }
}

// Update animated text boxes and remove text boxes whose duration is expired
ui_system_text_box_update :: proc() {
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
        }
      }
    }

    if item.duration == -1 do continue

    time_diff := time.duration_milliseconds(time.diff(time_source, time.now()))
    if time_diff > item.duration do append(&to_delete, idx)
  }

  for idx in to_delete {
    unordered_remove(&text_boxes, idx)

  }
}

// Misc system to keep the camera position to the center of the screen
ui_system_update_camera_position :: proc() {
  box := engine.database_get_component(globals.player_id, &table_bounding_boxes[globals.PLAYER_LAYER]).box

  engine.camera.target = rl.Vector2 { f32(box.x), f32(box.y) }
}



//
// PRIVATE
//



@(private="file")
BUTTON_SPACING: i32 = 15

@(private="file")
TEXT_PADDING: i32 = 10

@(private="file")
TEXT_WIDTH_THRESHOLD: i32 = 200


@(private="file")
// TextBox metadata containing all infos to draw it
TextBoxMetadata :: struct {
  using base: engine.Metadata,

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

@(private="file")
// TextBox storage
text_boxes: [dynamic]TextBoxMetadata


@(private="file")
ui_text_box_draw_from_metadata :: proc(metadata: ^TextBoxMetadata, position: [2]i32) {
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
ui_text_box_generate_metadata :: proc(metadata: ^TextBoxMetadata, text: string, font_size: i32, color: rl.Color) {
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

  metadata.text_height = (metadata.lines + 1) * font_size
  metadata.box_height = metadata.text_height + (TEXT_PADDING * 2)
  metadata.box_width = metadata.text_width + (TEXT_PADDING * 2)
  metadata.color = color
}
