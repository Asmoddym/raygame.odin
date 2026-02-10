package ui

import "../engine"

default_font_size :: proc() -> i32 {
  return engine.game_state.resolution.x / 80
}
