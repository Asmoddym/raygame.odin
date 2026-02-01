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

get_current_hovered_cell_coords :: proc() -> [2]i32 {
  coords := to_cell_coords(rl.GetScreenToWorld2D(rl.GetMousePosition(), engine.camera))

  coords.x = min(coords.x, _handle.cell_count_per_side)
  coords.x = max(coords.x, 0)
  coords.y = min(coords.y, _handle.cell_count_per_side)
  coords.y = max(coords.y, 0)

  return coords
}

// Returns coords to tile and chunk index
coords_to_tile_index :: proc(coords: [2]i32) -> (int, int) {
  cell_idx := int(coords[1] * _handle.cell_count_per_side + coords[0])
  chunk_idx := int((coords[1] / CHUNK_SIZE) * _handle.chunks_per_side + coords[0] / CHUNK_SIZE)

  return cell_idx, chunk_idx
}
