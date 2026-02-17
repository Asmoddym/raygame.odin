package ui

import "core:strings"
import "core:time"
import rl "vendor:raylib"

// Draw a simple text box without storing anything. Works nice for little texts.
text_box_draw_fast :: proc(text: string, x, y: i32, font_size: i32 = -1, color: rl.Color = rl.WHITE) {
  text_box: TextBoxMetadata

  text_box_generate_metadata(&text_box, text, font_size == -1 ? default_font_size() : font_size, color)
  text_box_draw_from_metadata(&text_box, { x, y })
}



//
// PRIVATE
//



@(private="file")
TEXT_PADDING: i32 = 10

@(private="file")
TEXT_WIDTH_THRESHOLD: i32 = 200


// TextBox metadata containing all infos to draw it
@(private="file")
TextBoxMetadata :: struct {
  id: int,
  owner_id: ^int,
  keep_alive_until_false: ^bool,

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
text_box_draw_from_metadata :: proc(metadata: ^TextBoxMetadata, position: [2]i32) {
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
text_box_generate_metadata :: proc(metadata: ^TextBoxMetadata, text: string, font_size: i32, color: rl.Color) {
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

  if metadata.text_width < current_width {
    metadata.text_width = current_width
  }

  metadata.text_height = (metadata.lines + 1) * font_size
  metadata.box_height = metadata.text_height + (TEXT_PADDING * 2)
  metadata.box_width = metadata.text_width + (TEXT_PADDING * 2)
  metadata.color = color
}
