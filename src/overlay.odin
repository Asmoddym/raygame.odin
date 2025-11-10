package macro

import "engine"
import rl "vendor:raylib"



//
// SYSTEMS
//



// Pause mode toggling system
overlay_system_toggle :: proc() {
  if rl.IsKeyPressed(.ESCAPE) {
    engine.game_state.in_overlay = !engine.game_state.in_overlay

    current_overlay = engine.game_state.in_overlay ? .PAUSE : .NONE
  }

  if rl.IsKeyPressed(.TAB) {
    engine.game_state.in_overlay = !engine.game_state.in_overlay

    current_overlay = engine.game_state.in_overlay ? .MENU : .NONE
  }
}

// General overlay system
overlay_system_main :: proc() {

  switch current_overlay {
  case .PAUSE:
    overlay_subsystem_pause()
    break
  case .MENU:
    overlay_subsystem_menu()
    break
  case .NONE:
    break
  }
}



//
// PRIVATE
//



OverlayType :: enum {
  PAUSE,
  MENU,
  NONE,
}

current_overlay: OverlayType = .NONE

overlay_subsystem_pause :: proc() {
  // rl.ClearBackground(rl.BLACK)

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


overlay_subsystem_menu :: proc() {
  @(static) selection := 0

  if rl.IsKeyPressed(rl.KeyboardKey.UP) do selection -= 1
  if rl.IsKeyPressed(rl.KeyboardKey.DOWN) do selection += 1

  if selection < 0 do selection = 2
  if selection > 2 do selection = 0

  ui_button_draw_xy_centered_list(
    { "MENU" },
    font_size = 40,
    on_click = {
      proc() { engine.game_state.closed = true },
    },
    selected = selection,
  )
}

