package systems

import rl "vendor:raylib"
import "../ui"
import "../engine"

pause_system :: proc() {
  @(static) selection := 0

  if rl.IsKeyPressed(rl.KeyboardKey.UP) do selection -= 1
  if rl.IsKeyPressed(rl.KeyboardKey.DOWN) do selection += 1

  if selection < 0 do selection = 2
  if selection > 2 do selection = 0

  ui.draw_xy_centered_button_list(
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

