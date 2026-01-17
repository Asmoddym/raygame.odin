package macro

import "core:fmt"
import "engine"
import "enums"
import "ui"
import rl "vendor:raylib"

// Pause system with its own input handling (for now at least)
pause_system :: proc() {
  if rl.IsKeyPressed(.ESCAPE) {
    if engine.game_state.current_scene.id != int(enums.SceneID.PAUSE) {
      engine.scene_set_current(enums.SceneID.PAUSE)
      selection = 0
    } else {
      engine.scene_set_current(enums.SceneID.MAIN)
    }
  }

  if engine.game_state.current_scene.id != 1 do return

  if rl.IsKeyPressed(.ENTER) {
    on_clicks[selection]()
  }

  ui.button_draw_xy_centered_list(
    texts,
    font_size = 40,
    on_click = proc(id: int) {
      on_clicks[id]()
    },
    selection = &selection,
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

@(private="file")
selection := 0

