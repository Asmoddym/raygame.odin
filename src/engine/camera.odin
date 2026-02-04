package engine

import rl "vendor:raylib"


// Camera global variable
// TODO: Maybe put this in the game_state? Or somewhere else?
camera: rl.Camera2D

// Current camera pointer
current_camera: ^rl.Camera2D


//
// INTERNAL API
//



// Initialize the camera from the screen resolution
camera_init :: proc() {
  camera_reset_zoom()

  camera.target = rl.Vector2 { f32(game_state.resolution.x) / 2 / camera.zoom, f32(game_state.resolution.y) / 2 / camera.zoom }
  camera.rotation = 0.0

  rl.SetMousePosition(game_state.resolution.x / 2, game_state.resolution.y / 2)

  camera_set_offset_based_on_resolution()
}

// Set the camera offset from the screen resolution
camera_set_offset_based_on_resolution :: proc() {
  camera.offset = rl.Vector2 { f32(game_state.resolution.x) / 2, f32(game_state.resolution.y) / 2 }
}

// Set the zoom based on a little resolution calculation
camera_reset_zoom :: proc() {
  camera.zoom = 0.8
}

camera_set_current_camera :: proc(camera: ^rl.Camera2D) {
  current_camera = camera
  rl.BeginMode2D(camera^)
}

