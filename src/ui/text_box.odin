package ui

import "core:strings"
import rl "vendor:raylib"

@(private="file")
TEXT_PADDING: i32 = 10

@(private="file")
TEXT_WIDTH_THRESHOLD: i32 = 175

draw_text_box:: proc(text: string, font_size: i32, position: rl.Vector2, color: rl.Color = rl.WHITE) {

  // TODO: Optimize this.
  //
  // - Maybe create an array of words and calculate their width, and place them in lines

  // TODO: Add an "position_type" enum to be able to pre-calculate the width of the textbox and display it at the center of the player

  spacing := font_size / 10

  width: i32 = 0
  x := i32(position.x) + TEXT_PADDING
  y := i32(position.y) + TEXT_PADDING
  lines: i32 = 0

  max_width: i32 = 0

  for i := 0; i < len(text); i += 1 {
    str := strings.concatenate({text[i:i + 1]})
    cstr := strings.unsafe_string_to_cstring(str)
    char_width := i32(rl.MeasureText(cstr, font_size))

    rl.DrawText(cstr, x, y + lines * font_size, font_size, color)

    x += char_width + spacing
    width += i32(char_width + spacing)

    if i + 1 < len(text) {
      next_space := strings.index_any(text[i + 1:], " ")
      if next_space != -1 {
        next_word := strings.concatenate({text[i + 1:i + 1 + next_space]})
        next_cword := strings.unsafe_string_to_cstring(next_word)
        next_word_width := i32(rl.MeasureText(next_cword, font_size))

        if width + next_word_width + spacing * i32(len(next_word)) > TEXT_WIDTH_THRESHOLD {
          max_width = max_width < width ? width : max_width
          x = i32(position.x) + TEXT_PADDING
          lines += 1
          width = 0
        }
      }
    }
  }

  max_width = max_width < width ? width : max_width

  rl.DrawRectangleLines(i32(position.x), i32(position.y), max_width + TEXT_PADDING * 2, (lines + 1) * font_size + TEXT_PADDING * 2, color)
}
