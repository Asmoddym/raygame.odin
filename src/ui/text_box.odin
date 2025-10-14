package ui

import "core:strings"
import rl "vendor:raylib"

@(private="file")
TEXT_PADDING: i32 = 10

@(private="file")
TEXT_WIDTH_THRESHOLD: i32 = 175

draw_text_box:: proc(text: string, font_size: i32, position: rl.Vector2, color: rl.Color = rl.WHITE) {
  words := strings.split(text, " ")
  i32_position: [2]i32 = { i32(position.x), i32(position.y) }

  cwords: [dynamic]cstring
  words_position: [dynamic][2]i32

  current_width: i32 = 0
  current_line: i32 = 0
  max_width: i32 = 0

  for word in words {
    cword := strings.unsafe_string_to_cstring(strings.concatenate({word}))
    append(&cwords, cword)
    size := rl.MeasureText(cword, font_size)

    if current_width > TEXT_WIDTH_THRESHOLD {
      if max_width < current_width {
        max_width = current_width
      }

      current_line += 1
      current_width = 0
    }

    append(&words_position, [2]i32 { current_width, current_line * font_size })

    current_width += size + TEXT_PADDING
  }

  for i: int = 0; i < len(words); i += 1 {
    word_position := words_position[i]

    rl.DrawText(cwords[i], word_position.x + i32_position.x + TEXT_PADDING, word_position.y + i32_position.y + TEXT_PADDING, font_size, color)
  }

  rl.DrawRectangleLines(i32_position.x, i32_position.y, max_width + TEXT_PADDING * 2, (current_line + 1) * font_size + TEXT_PADDING * 2, color)
}
