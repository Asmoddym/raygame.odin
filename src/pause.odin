package macro

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

  engine.scene_overlay_draw(0, render_pause)
}

pause_init :: proc(overlay: ^engine.Overlay) {
  for idx in 0..<len(texts) {
    text := texts[idx]

    ui.simple_button_create(idx, text, overlay, { 0.5, 0.5 - (f32(len(texts) - 1) * 0.1) + f32(idx + 1) * 0.1 }, 40)
  }
}

render_pause :: proc(overlay: ^engine.Overlay) {
  if rl.IsKeyPressed(.ENTER)                 do on_clicks[selection]()
  if rl.IsKeyPressed(rl.KeyboardKey.UP)      do selection = selection - 1 < 0 ? len(texts) - 1 : selection - 1
  if rl.IsKeyPressed(rl.KeyboardKey.DOWN)    do selection = (selection + 1) % len(texts)

  for idx in 0..<len(texts) {
    selected_by_mouse, clicked := ui.persistable_button_draw(idx, overlay, selection == idx)

    if selected_by_mouse do selection = idx
    if clicked           do on_clicks[idx]()
  }
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

