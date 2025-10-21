package components

import "core:strings"
import "core:time"
import "../engine"
import "../constants"
import rl "vendor:raylib"

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
