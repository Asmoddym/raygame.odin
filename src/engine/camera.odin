package engine

import rl "vendor:raylib"

camera: rl.Camera2D

init_camera :: proc(resolution: [2]i32) {
  camera.target = rl.Vector2 { 0, 0 }
  init_camera_offset(resolution)
  camera.rotation = 0.0
  camera.zoom = 1.0
}

init_camera_offset :: proc(resolution: [2]i32) {
  camera.offset = rl.Vector2 { f32(resolution.x) / 2, f32(resolution.y) / 2 }
}
