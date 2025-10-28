package macro

import "engine"
import rl "vendor:raylib"



//
// SYSTEMS
//



// Pause mode toggling system
pause_system_toggle :: proc() {
  if rl.IsKeyPressed(.ESCAPE) do engine.game_state.paused = !engine.game_state.paused
}

// General pause system
pause_system_main :: proc() {
  @(static) selection := 0

  if rl.IsKeyPressed(rl.KeyboardKey.UP) do selection -= 1
  if rl.IsKeyPressed(rl.KeyboardKey.DOWN) do selection += 1

  if selection < 0 do selection = 2
  if selection > 2 do selection = 0

  ui_button_draw_xy_centered_list(
    { "Toggle borderless window", "Toggle fullscreen", "Exit" },
    font_size = 40,
    on_click = {
      proc() { engine.game_state.borderless_window = !engine.game_state.borderless_window },
      proc() { engine.game_state.fullscreen = !engine.game_state.fullscreen },
      proc() { engine.game_state.closed = true },
    },
    selected = selection,
  )
}
