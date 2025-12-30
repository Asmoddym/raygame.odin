package engine

import rl "vendor:raylib"


// Camera global variable
// TODO: Maybe put this in the game_state? Or somewhere else?
camera: rl.Camera2D



//
// INTERNAL API
//



// Initialize the camera from the screen resolution
camera_init :: proc() {
  camera.target = rl.Vector2 { 0, 0 }
  camera.rotation = 0.0

  rl.SetMousePosition(game_state.resolution.x / 2, game_state.resolution.y / 2)

  camera_set_offset_based_on_resolution()
  camera_set_zoom_based_on_resolution()
}

// Set the camera offset from the screen resolution
camera_set_offset_based_on_resolution :: proc() {
  // camera.offset = rl.Vector2 { f32(game_state.resolution.x) / 2, f32(game_state.resolution.y) / 2 }
}

// Set the zoom based on a little resolution calculation
camera_set_zoom_based_on_resolution :: proc() {
  camera.zoom = (f32(game_state.resolution.x) / f32(BASE_RESOLUTION.x)) / 1.2
}
