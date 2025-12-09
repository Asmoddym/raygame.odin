package macro

import "engine"
import "enums"
import rl "vendor:raylib"


// Pause mode toggling system
pause_system_toggle :: proc() {
  if rl.IsKeyPressed(.ESCAPE) {
    engine.scene_set_current(engine.game_state.current_scene.id == int(enums.SceneID.PAUSE) ? enums.SceneID.MAIN : enums.SceneID.PAUSE)
  }
}

// Pause system with its own input handling (for now at least)
// TODO: Challenge that
pause_system_main :: proc() {
  @(static) selection := 0

  if engine.game_state.current_scene.id != 1 do return

  if rl.IsKeyPressed(rl.KeyboardKey.UP) do selection -= 1
  if rl.IsKeyPressed(rl.KeyboardKey.DOWN) do selection += 1

  if selection < 0 do selection = 2
  if selection > 2 do selection = 0

  if rl.IsKeyPressed(.ENTER) do on_clicks[selection]()

  ui_button_draw_xy_centered_list(
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
