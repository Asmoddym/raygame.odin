package ui

import "core:strings"
import rl "vendor:raylib"

@(private="file")
TEXT_PADDING: i32 = 10

@(private="file")
TEXT_WIDTH_THRESHOLD: i32 = 175

draw_text_box:: proc(text: string, font_size: i32, position: rl.Vector2, color: rl.Color = rl.WHITE) {
  @(static)bytes: [256]byte
  builder := strings.builder_from_bytes(bytes[:])

  words := strings.split(text, " ")
  i32_position: [2]i32 = { i32(position.x), i32(position.y) }

  current_width: i32 = 0
  current_line: i32 = 0
  max_width: i32 = 0

  for word in words {
    strings.builder_reset(&builder)
    strings.write_string(&builder, word)
    cword := strings.to_cstring(&builder)

    size := rl.MeasureText(cword, font_size)

    if current_width > TEXT_WIDTH_THRESHOLD {
      if max_width < current_width {
        max_width = current_width
      }

      current_line += 1
      current_width = 0
    }

    rl.DrawText(cword, current_width + i32_position.x + TEXT_PADDING, (current_line * font_size) + i32_position.y + TEXT_PADDING, font_size, color)
    current_width += size + TEXT_PADDING
  }

  rl.DrawRectangleLines(i32_position.x, i32_position.y, max_width + TEXT_PADDING * 2, (current_line + 1) * font_size + TEXT_PADDING * 2, color)
}
