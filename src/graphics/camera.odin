package graphics

import rl "vendor:raylib"

camera: rl.Camera2D

init_camera :: proc(screen_width: i32, screen_height: i32) {
  camera.target = rl.Vector2 { 0, 0 }
  camera.offset = rl.Vector2 { f32(screen_width) / 2, f32(screen_height) / 2 }
  camera.rotation = 0.0
  camera.zoom = 1.0

}
