package terrain

import "../engine"
import rl "vendor:raylib"

// Calculate the total pixel length of the map side.
map_side_pixel_size :: proc() -> i32 {
  return CHUNK_PIXEL_SIZE * i32(_handle.chunks_per_side)
}

f32_map_side_pixel_size :: proc() -> f32 {
  return f32(map_side_pixel_size())
}

// Ensure zoom is capped.
ensure_zoom_capped :: proc() {
  engine.camera.zoom = min(ZOOM_INTERVAL[1], engine.camera.zoom)
  engine.camera.zoom = max(ZOOM_INTERVAL[0], engine.camera.zoom)

  first_point := rl.GetWorldToScreen2D({ 0, 0 }, engine.camera)
  last_point := rl.GetWorldToScreen2D({ f32_map_side_pixel_size(), f32_map_side_pixel_size() }, engine.camera)

  too_zoomed_x := last_point.x - first_point.x < f32(engine.game_state.resolution.x)
  too_zoomed_y := last_point.y - first_point.y < f32(engine.game_state.resolution.y)

  if too_zoomed_x || too_zoomed_y {
    engine.camera.zoom = f32(engine.game_state.resolution.x) / f32_map_side_pixel_size()
  }

  ensure_camera_capped()
}

// Ensure camera is in frame
ensure_camera_capped :: proc() {
  // I can't use GetWorldToScreen2D because the result would move as I'm scrolling
  first_point := rl.Vector2 {
    engine.camera.offset.x / engine.camera.zoom,
    engine.camera.offset.y / engine.camera.zoom,
  }

  last_point := rl.Vector2 {
    (f32_map_side_pixel_size() + first_point.x) - f32(engine.game_state.resolution.x) / engine.camera.zoom,
    (f32_map_side_pixel_size() + first_point.y) - f32(engine.game_state.resolution.y) / engine.camera.zoom,
  }

  // engine.camera.target.x += relative_to_zoom(_manipulation_state.target_delta.x)
  engine.camera.target.x = max(first_point.x, engine.camera.target.x)
  engine.camera.target.x = min(last_point.x, engine.camera.target.x)

  // engine.camera.target.y += relative_to_zoom(_manipulation_state.target_delta.y)
  engine.camera.target.y = max(first_point.y, engine.camera.target.y)
  engine.camera.target.y = min(last_point.y, engine.camera.target.y)
}
