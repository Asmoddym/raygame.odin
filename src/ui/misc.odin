package ui

import "../engine"
import rl "vendor:raylib"

default_font_size :: proc() -> i32 {
  return engine.game_state.resolution.x / 80
}

default_font_height :: proc() -> i32 {
  return i32(rl.MeasureTextEx(rl.GetFontDefault(), "A", f32(default_font_size()), 1).y)
}
