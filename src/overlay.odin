package macro

import "engine"
import rl "vendor:raylib"


// Overlay type and declaration, public to be checked in input system for example
OverlayType :: enum {
  PAUSE,
  MENU,
  NONE,
}

overlay_current: OverlayType = .NONE



//
// SYSTEMS
//



// Pause mode toggling system
overlay_system_toggle :: proc() {
  if rl.IsKeyPressed(.ESCAPE) {
    overlay_current = overlay_current == .NONE ? .PAUSE : .NONE

    engine.game_state.in_blocking_overlay = overlay_current == .PAUSE
  }

  if rl.IsKeyPressed(.TAB) && !engine.game_state.in_blocking_overlay {
    overlay_current = overlay_current == .NONE ? .MENU : .NONE
  }
}

// General overlay system
overlay_system_main :: proc() {
  switch overlay_current {
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



// Pause subsystem, considered blocking
@(private="file")
overlay_subsystem_pause :: proc() {
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

// Menu subsystem, considered non-blocking
@(private="file")
overlay_subsystem_menu :: proc() {
  @(static) selection := 0

  if rl.IsKeyPressed(rl.KeyboardKey.UP) do selection -= 1
  if rl.IsKeyPressed(rl.KeyboardKey.DOWN) do selection += 1

  if selection < 0 do selection = 2
  if selection > 2 do selection = 0

  ui_button_draw_xy_centered_list(
    { "MENU", "COUCOU" },
    font_size = 40,
    on_click = {
      proc() { engine.game_state.closed = true },
      proc() { engine.game_state.closed = true },
    },
    selected = selection,
  )
}

