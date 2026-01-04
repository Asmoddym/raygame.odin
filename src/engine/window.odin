package engine

import rl "vendor:raylib"



//
// INTERNAL API
//


BASE_RESOLUTION: [2]i32 = { 1600, 900 }
// BASE_RESOLUTION: [2]i32 = { 2560, 1440}



// Initialize window from a resolution
window_init :: proc() {
  rl.InitWindow(BASE_RESOLUTION.x, BASE_RESOLUTION.y, "coucou")

  rl.SetTargetFPS(rl.GetMonitorRefreshRate(rl.GetCurrentMonitor()))

  game_state.resolution = BASE_RESOLUTION

  game_state.borderless_window = false
  // game_state.borderless_window = true
  // window_toggle_mode(game_state.borderless_window, proc() { rl.ToggleBorderlessWindowed() })

  rl.SetExitKey(.KEY_NULL)
}

// Generic screen mode switcher.
// Resets resolution and initializes camera independently from the selected mode.
// toggler contains a proc performing the actual switch.
window_toggle_mode :: proc(toggle: bool, toggler: proc()) {
  if toggle {
    when ODIN_OS == .Darwin do toggler()

    game_state.resolution = { rl.GetMonitorWidth(rl.GetCurrentMonitor()), rl.GetMonitorHeight(rl.GetCurrentMonitor()) }
    rl.SetWindowSize(game_state.resolution.x, game_state.resolution.y)

    when ODIN_OS == .Windows do toggler()
  } else {
    toggler()
    game_state.resolution = { 1280, 720 }
    rl.SetWindowSize(game_state.resolution.x, game_state.resolution.y)
  }

  camera_set_offset_based_on_resolution()
  camera_set_zoom_based_on_resolution()
  scene_overlay_update_resolutions()

  rl.SetConfigFlags({ rl.ConfigFlag.WINDOW_HIGHDPI })
}
