package engine

import rl "vendor:raylib"



//
// INTERNAL API
//



// Initialize window from a resolution
window_init :: proc(resolution: [2]i32) {
  rl.InitWindow(resolution.x, resolution.y, "coucou")

  rl.SetTargetFPS(rl.GetMonitorRefreshRate(rl.GetCurrentMonitor()))

  game_state.resolution = {
    resolution.x == 0 ? rl.GetMonitorWidth(rl.GetCurrentMonitor()) : resolution.x,
    resolution.y == 0 ? rl.GetMonitorHeight(rl.GetCurrentMonitor()) : resolution.y,
  }

  game_state.borderless_window = false

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
    game_state.resolution = { 1024, 768 }
    rl.SetWindowSize(game_state.resolution.x, game_state.resolution.y)
  }

  camera_init_offset(game_state.resolution)
  overlay_update_resolutions()

  rl.SetConfigFlags({ rl.ConfigFlag.WINDOW_HIGHDPI })
}
