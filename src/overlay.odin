package macro

import "core:strings"
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
    overlay_current = overlay_current == .PAUSE ? .NONE : .PAUSE

    engine.game_state.overlay.blocking = overlay_current == .PAUSE
  }

  if rl.IsKeyPressed(.TAB) && !engine.game_state.overlay.blocking {
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

  rl.EndTextureMode()
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

  overlay := &engine.game_state.overlay

  if rl.IsKeyPressed(rl.KeyboardKey.UP) do selection -= 1
  if rl.IsKeyPressed(rl.KeyboardKey.DOWN) do selection += 1

  if selection < 0 do selection = 1
  if selection > 1 do selection = 0

  rl.BeginTextureMode(overlay.render_texture)
  rl.ClearBackground(rl.PURPLE)

  rl.DrawText(strings.unsafe_string_to_cstring("coucou"), 100, 200, 20, rl.WHITE)


  ui_button_draw_xy_centered_list(
    { "MENU", "COUCOU" },
    font_size = 40,
    on_click = {
      proc() { engine.game_state.closed = true },
      proc() { engine.game_state.closed = true },
    },
    selected = selection,
    resolution = overlay.resolution,
  )
  rl.EndTextureMode()

  rl.DrawTexturePro(overlay.render_texture.texture,
    rl.Rectangle { 0, 0, f32(overlay.resolution.x), -f32(overlay.resolution.y) },
    rl.Rectangle { f32(engine.game_state.resolution.x - overlay.resolution.x) / 2, f32(engine.game_state.resolution.y - overlay.resolution.y) / 2, f32(overlay.resolution.x), f32(overlay.resolution.y) },
    rl.Vector2 { 0, 0 }, 0, rl.WHITE)

  rl.DrawRectangleLinesEx(
    rl.Rectangle {
    f32((engine.game_state.resolution.x - overlay.resolution.x) / 2),
    f32((engine.game_state.resolution.y - overlay.resolution.y) / 2),
      f32(overlay.resolution.x),
      f32(overlay.resolution.y),
    }, 2, rl.WHITE,
  )
}

