package macro

import "engine"
import "globals"
import "core:strings"
import "core:time"
import rl "vendor:raylib"


// COMPONENTS DEFINITION


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
}

Component_TextBox :: struct {
  using base: engine.Component(TextBoxMetadata),

  duration: f64,
  instanciated_at: time.Time,
  attached_to_box: ^rl.Rectangle,

  animated: bool,
  ticks: int,
}

table_text_boxes: engine.Table(Component_TextBox)


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
ui_text_box_init :: proc(component: ^Component_TextBox, text: string, font_size: i32, attached_to_entity_id: int, duration: f64 = -1, color: rl.Color = rl.WHITE) {
  component.duration = duration
  component.instanciated_at = time.now()
  component.attached_to_box = &engine.database_get_component(attached_to_entity_id, &table_bounding_boxes).box

  ui_text_box_generate_metadata(&component.metadata, text, font_size, color)

  component.animated = false
  component.ticks = 0
}

// Init an animated text box, generating and storing the metadata to the component pointer
ui_animated_text_box_init :: proc(component: ^Component_TextBox, text: string, font_size: i32, attached_to_entity_id: int, duration: f64 = -1, color: rl.Color = rl.WHITE) {
  ui_text_box_init(component, text, font_size, attached_to_entity_id, duration, color)

  component.animated = true
}



//
// SYSTEMS
//



// Draw text boxes
ui_system_text_box_draw :: proc() {
  for &item in table_text_boxes.items {
    box := item.attached_to_box

    if box != nil {
      position := rl.Vector2 { box.x + box.width, box.y }

      if item.animated {
        ui_animated_text_box_draw(&item.metadata, position, item.ticks)
      } else {
        ui_text_box_draw(&item.metadata, position)
      }
    }
  }
}

// Update animated text boxes and remove text boxes whose duration is expired
ui_system_text_box_update :: proc() {
  to_delete: [dynamic]int

  for &item in table_text_boxes.items {
    time_diff := time.duration_milliseconds(time.diff(item.instanciated_at, time.now()))

    if item.animated && item.ticks != item.metadata.text_len {
      // 30ms for each letter
      item.ticks = int(time_diff / 30)
      if item.ticks > item.metadata.text_len do item.ticks = item.metadata.text_len
    }

    if item.duration != -1 && time_diff > item.duration {
      append(&to_delete, item.entity_id)
    }
  }

  for id in to_delete {
    engine.database_destroy_component(id, &table_text_boxes)
  }
}

// Misc system to keep the camera position to the center of the screen
ui_system_update_camera_position :: proc() {
  box := engine.database_get_component(globals.player, &table_bounding_boxes).box

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
ui_text_box_draw :: proc(metadata: ^TextBoxMetadata, position: rl.Vector2, color: rl.Color = rl.WHITE) {
  i32_position: [2]i32 = { i32(position.x), i32(position.y) - metadata.box_height }
  ui_text_box_draw_from_metadata(metadata, i32_position) 
}

@(private="file")
ui_animated_text_box_draw :: proc(metadata: ^TextBoxMetadata, position: rl.Vector2, ticks: int, color: rl.Color = rl.WHITE) {
  i32_position: [2]i32 = { i32(position.x), i32(position.y) - metadata.box_height }

  metadata.words = strings.split(metadata.text[:ticks], " ")
  ui_text_box_draw_from_metadata(metadata, i32_position)
}

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
