package components

import rl "vendor:raylib"

Metadata :: struct {
}

TextBoxMetadata :: struct {
  using base: Metadata,

  lines: i32,
  text_width: i32,
  box_width: i32,
  text_height: i32,
  box_height: i32,

  words_position: [dynamic][2]i32,
  words: []string,
  text: string,
  font_size: i32,
  color: rl.Color,
}

MetadataUnion :: union {
  TextBoxMetadata,
  Metadata,
}
