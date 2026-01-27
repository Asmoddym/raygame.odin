package terrain

import "../engine"
import rl "vendor:raylib"

// Returns given position to its currently hovered cell in-map coordinates, regardless of zoom and camera offsets,.
//
// /!\ This doesn't return the cell x and y coords, but the actual position (aka multiples of cell dimensions), like (16, 32).
to_cell_coords :: proc(pos: [2]f32) -> [2]i32 {
  return { i32(pos.x / F32_TILE_SIZE), i32(pos.y / F32_TILE_SIZE) }
}

relative_to_zoom :: proc(value: $T) -> f32 {
  return f32(value) * 1 / engine.camera.zoom
}

get_current_hovered_zone_to_cell_coords :: proc() -> ([2]i32, [2]i32) {
  coords := to_cell_coords(rl.GetScreenToWorld2D(rl.GetMousePosition(), engine.camera))
  first_point: [2]i32 = { coords.x - 3, coords.y - 3 }
  last_point: [2]i32 = { coords.x + 3, coords.y + 3 }

  first_point.x = min(first_point.x, _handle.cell_count_per_side)
  first_point.x = max(first_point.x, 0)
  first_point.y = min(first_point.y, _handle.cell_count_per_side)
  first_point.y = max(first_point.y, 0)
  last_point.x = min(last_point.x, _handle.cell_count_per_side)
  last_point.x = max(last_point.x, 0)
  last_point.y = min(last_point.y, _handle.cell_count_per_side)
  last_point.y = max(last_point.y, 0)

  return first_point, last_point
}
