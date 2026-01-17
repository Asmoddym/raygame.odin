package macro

import "engine"
import "enums"
import "ui"
import rl "vendor:raylib"

// Pause system with its own input handling (for now at least)
pause_system :: proc() {
  @(static) selection := 0

  if rl.IsKeyPressed(.ESCAPE) {
    engine.scene_set_current(engine.game_state.current_scene.id == int(enums.SceneID.PAUSE) ? enums.SceneID.MAIN : enums.SceneID.PAUSE)
  }

  if engine.game_state.current_scene.id != 1 do return

  if rl.IsKeyPressed(rl.KeyboardKey.UP) do selection -= 1
  if rl.IsKeyPressed(rl.KeyboardKey.DOWN) do selection += 1

  if selection < 0 do selection = len(texts) - 1
  if selection > len(texts) - 1 do selection = 0

  if rl.IsKeyPressed(.ENTER) do on_clicks[selection]()

  ui.button_draw_xy_centered_list(
    texts,
    font_size = 40,
    on_click = on_clicks,
    selected = selection,
  )
}



//
// PRIVATE
//



@(private="file")
on_clicks: []proc() = {
  proc() { engine.game_state.borderless_window = !engine.game_state.borderless_window },
  proc() { engine.game_state.fullscreen = !engine.game_state.fullscreen },
  proc() { engine.game_state.closed = true },
}

@(private="file")
texts: []string = { "Toggle borderless window", "Toggle fullscreen", "Exit" }
