package ui

import "../components"
import "../constants"
import "core:strings"
import rl "vendor:raylib"

draw_from_metadata :: proc(metadata: ^components.TextBoxMetadata, position: [2]i32) {
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

draw_text_box :: proc(metadata: ^components.TextBoxMetadata, position: rl.Vector2, color: rl.Color = rl.WHITE) {
  i32_position: [2]i32 = { i32(position.x), i32(position.y) - metadata.box_height }

  draw_from_metadata(metadata, i32_position) 
}

draw_animated_text_box :: proc(metadata: ^components.TextBoxMetadata, position: rl.Vector2, ticks: int, color: rl.Color = rl.WHITE) {
  i32_position: [2]i32 = { i32(position.x), i32(position.y) - metadata.box_height }

  metadata.words = strings.split(metadata.text[:ticks], " ")

  draw_from_metadata(metadata, i32_position)
}
