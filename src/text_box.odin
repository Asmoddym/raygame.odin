package macro

import "constants"
import "core:strings"
import rl "vendor:raylib"
import "core:time"
import "engine"


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

// Text

Component_TextBox :: struct {
  using base: engine.Component(TextBoxMetadata),

  duration: f64,
  instanciated_at: time.Time,
  attached_to_box: ^rl.Rectangle,

  animated: bool,
  ticks: int,
}

table_text_boxes: engine.Table(Component_TextBox)

text_box__draw_from_metadata :: proc(metadata: ^TextBoxMetadata, position: [2]i32) {
  bytes: [256]byte
  builder := strings.builder_from_bytes(bytes[:])

  rl.DrawRectangle(position.x, position.y, metadata.box_width, metadata.box_height, rl.BLACK)
  rl.DrawRectangleLines(position.x, position.y, metadata.box_width, metadata.box_height, rl.WHITE)

  for i: int = 0; i < len(metadata.words); i += 1 {
    strings.write_string(&builder, metadata.words[i])
    cword := strings.to_cstring(&builder)

    word_position := metadata.words_position[i]
    rl.DrawText(cword, word_position.x + position.x + constants.TEXT_PADDING, word_position.y + position.y + constants.TEXT_PADDING, metadata.font_size, metadata.color)

    strings.builder_reset(&builder)
  }
}

text_box__draw_text_box :: proc(metadata: ^TextBoxMetadata, position: rl.Vector2, color: rl.Color = rl.WHITE) {
  i32_position: [2]i32 = { i32(position.x), i32(position.y) - metadata.box_height }
  text_box__draw_from_metadata(metadata, i32_position) 
}

text_box__draw_animated_text_box :: proc(metadata: ^TextBoxMetadata, position: rl.Vector2, ticks: int, color: rl.Color = rl.WHITE) {
  i32_position: [2]i32 = { i32(position.x), i32(position.y) - metadata.box_height }

  metadata.words = strings.split(metadata.text[:ticks], " ")
  text_box__draw_from_metadata(metadata, i32_position)
}

generate_metadata :: proc(metadata: ^TextBoxMetadata, text: string, font_size: i32, color: rl.Color) {
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

    if current_width > constants.TEXT_WIDTH_THRESHOLD {
      metadata.lines += 1
      current_width = 0
    }

    append(&metadata.words_position, [2]i32 { current_width, metadata.lines * font_size })

    current_width += size + constants.TEXT_PADDING

    strings.builder_reset(&builder)
  }

  metadata.text_height = (metadata.lines + 1) * font_size
  metadata.box_height = metadata.text_height + (constants.TEXT_PADDING * 2)
  metadata.box_width = metadata.text_width + (constants.TEXT_PADDING * 2)
  metadata.color = color
}

init_text_box :: proc(component: ^Component_TextBox, text: string, font_size: i32, attached_to_entity_id: int, duration: f64 = -1, color: rl.Color = rl.WHITE) {
  component.duration = duration
  component.instanciated_at = time.now()
  component.attached_to_box = &engine.database_get_component(attached_to_entity_id, &table_bounding_boxes).box

  generate_metadata(&component.metadata, text, font_size, color)

  component.animated = false
  component.ticks = 0
}

init_animated_text_box :: proc(component: ^Component_TextBox, text: string, font_size: i32, attached_to_entity_id: int, duration: f64 = -1, color: rl.Color = rl.WHITE) {
  init_text_box(component, text, font_size, attached_to_entity_id, duration, color)

  component.animated = true
}

draw_texts :: proc() {
  for &item in table_text_boxes.items {
    box := item.attached_to_box

    if box != nil {
      position := rl.Vector2 { box.x + box.width, box.y }

      if item.animated {
        text_box__draw_animated_text_box(&item.metadata, position, item.ticks)
      } else {
        text_box__draw_text_box(&item.metadata, position)
      }
    }
  }
}

update_texts :: proc() {
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

