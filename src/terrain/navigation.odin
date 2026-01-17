package terrain

import "../engine"
import rl "vendor:raylib"

// Main manipulation system (scroll, zoom, selection).
process_navigation :: proc() {
  system_mouse_inputs()
  system_keyboard_inputs()
}



// PRIVATE



// Handle mouse inputs
@(private="file")
system_mouse_inputs :: proc() {
  wheel_move := rl.GetMouseWheelMove()

  if wheel_move != 0 {
    engine.camera.zoom += wheel_move * ZOOM_SPEED

    ensure_zoom_capped()
  }

  if rl.IsMouseButtonDown(rl.MouseButton.LEFT) {
    delta := rl.GetMouseDelta()

    engine.camera.target.x -= relative_to_zoom(delta.x)
    engine.camera.target.y -= relative_to_zoom(delta.y)

    ensure_camera_capped()
  }
}

// Handle keyboard inputs
@(private="file")
system_keyboard_inputs :: proc() {
  time  := rl.GetFrameTime()
  value := relative_to_zoom(800 * time)

  delta: [2]f32 = { 0, 0 }

  if rl.IsKeyDown(rl.KeyboardKey.LEFT)  {
    delta[0] -= value
  }
  if rl.IsKeyDown(rl.KeyboardKey.RIGHT) {
    delta[0] += value
  }
  if rl.IsKeyDown(rl.KeyboardKey.UP)    {
    delta[1] -= value
  }
  if rl.IsKeyDown(rl.KeyboardKey.DOWN)  {
    delta[1] += value
  }

  if delta[0] != 0 || delta[1] != 0 {
    engine.camera.target.x += delta.x
    engine.camera.target.y += delta.y

    ensure_camera_capped()
  }
}
