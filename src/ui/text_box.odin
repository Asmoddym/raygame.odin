package ui

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

@(private="file")
TEXT_PADDING: i32 = 10

@(private="file")
TEXT_WIDTH_THRESHOLD: i32 = 200

@(private="file")
Metadata :: struct {
  lines: i32,
  text_width: i32,
  box_width: i32,
  text_height: i32,
  box_height: i32,
  position: [2]i32,

  words_position: [dynamic][2]i32,
  words: []string,

  builder: strings.Builder,
  text: string,
}

generate_metadata_v2 :: proc(metadata: ^Metadata, text: string, font_size: i32, position: rl.Vector2) {
  current_width: i32 = 0

  metadata.text = text
  metadata.words = strings.split(metadata.text, " ")

  for word in metadata.words {
    strings.write_string(&metadata.builder, word)

    cword := strings.to_cstring(&metadata.builder)
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

    strings.builder_reset(&metadata.builder)
  }

  metadata.text_height = (metadata.lines + 1) * font_size
  metadata.box_height = metadata.text_height + (TEXT_PADDING * 2)
  metadata.box_width = metadata.text_width + (TEXT_PADDING * 2)
  metadata.position = { i32(position.x), i32(position.y) - metadata.box_height }
}

draw_from_metadata :: proc(metadata: ^Metadata, font_size: i32, color: rl.Color) {
  rl.DrawRectangle(metadata.position.x, metadata.position.y, metadata.box_width, metadata.box_height, rl.BLACK)
  rl.DrawRectangleLines(metadata.position.x, metadata.position.y, metadata.box_width, metadata.box_height, rl.WHITE)

  for i: int = 0; i < len(metadata.words); i += 1 {
    strings.write_string(&metadata.builder, metadata.words[i])
    cword := strings.to_cstring(&metadata.builder)

    word_position := metadata.words_position[i]
    rl.DrawText(cword, word_position.x + metadata.position.x + TEXT_PADDING, word_position.y + metadata.position.y + TEXT_PADDING, font_size, color)

    strings.builder_reset(&metadata.builder)
  }
}

draw_text_box :: proc(text: string, font_size: i32, position: rl.Vector2, color: rl.Color = rl.WHITE) {
  bytes: [256]byte
  metadata: Metadata
  metadata.builder = strings.builder_from_bytes(bytes[:])

  generate_metadata_v2(&metadata, text, font_size, position)
  draw_from_metadata(&metadata, font_size, color)
}

draw_animated_text_box :: proc(text: string, font_size: i32, position: rl.Vector2, ticks: int, color: rl.Color = rl.WHITE) {
  bytes: [256]byte
  metadata: Metadata
  metadata.builder = strings.builder_from_bytes(bytes[:])

  generate_metadata_v2(&metadata, text, font_size, position)
  metadata.words = strings.split(text[:ticks], " ")

  draw_from_metadata(&metadata, font_size, color)
}
