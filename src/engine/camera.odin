package engine

import rl "vendor:raylib"


// Camera global variable
// TODO: Maybe put this in the game_state? Or somewhere else?
camera: rl.Camera2D



//
// INTERNAL API
//



// Initialize the camera from the screen resolution
camera_init :: proc(resolution: [2]i32) {
  camera.target = rl.Vector2 { 0, 0 }
  camera_init_offset(resolution)
  camera.rotation = 0.0
  camera.zoom = 1.0
}

// Initialize the camera offset from the screen resolution
camera_init_offset :: proc(resolution: [2]i32) {
  camera.offset = rl.Vector2 { f32(resolution.x) / 2, f32(resolution.y) / 2 }
}
