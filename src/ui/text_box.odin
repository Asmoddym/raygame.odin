package ui

import "core:strings"
import rl "vendor:raylib"

@(private="file")
TEXT_PADDING: i32 = 10

@(private="file")
TEXT_WIDTH_THRESHOLD: i32 = 200

draw_text_box:: proc(text: string, font_size: i32, position: rl.Vector2, color: rl.Color = rl.WHITE) {
  bytes: [256]byte
  builder := strings.builder_from_bytes(bytes[:])

  words_position: [dynamic][2]i32
  current_width: i32 = 0
  current_line: i32 = 0
  max_width: i32 = 0

  words := strings.split(text, " ")

  for word in words {
    strings.write_string(&builder, word)

    cword := strings.to_cstring(&builder)
    size := rl.MeasureText(cword, font_size)

    if max_width < current_width {
      max_width = current_width
    }

    if current_width > TEXT_WIDTH_THRESHOLD {
      current_line += 1
      current_width = 0
    }

    append(&words_position, [2]i32 { current_width, current_line * font_size })

    current_width += size + TEXT_PADDING

    strings.builder_reset(&builder)
  }

  total_text_height := (current_line + 1) * font_size
  total_box_height := total_text_height + (TEXT_PADDING * 2)

  i32_position: [2]i32 = { i32(position.x), i32(position.y) - total_box_height }

  rl.DrawRectangle(i32_position.x, i32_position.y, max_width + TEXT_PADDING * 2, total_box_height, rl.BLACK)
  rl.DrawRectangleLines(i32_position.x, i32_position.y, max_width + TEXT_PADDING * 2, total_box_height, color)

  for i: int = 0; i < len(words); i += 1 {
    strings.write_string(&builder, words[i])
    cword := strings.to_cstring(&builder)

    word_position := words_position[i]
    rl.DrawText(cword, word_position.x + i32_position.x + TEXT_PADDING, word_position.y + i32_position.y + TEXT_PADDING, font_size, color)

    strings.builder_reset(&builder)
  }
}
