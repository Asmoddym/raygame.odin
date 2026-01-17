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
