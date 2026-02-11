package terrain

import "../engine"
import rl "vendor:raylib"

// Returns given position to its currently hovered cell in-map coordinates, regardless of zoom and camera offsets,.
//
// /!\ This doesn't return the cell x and y coords, but the actual position (aka multiples of cell dimensions), like (16, 32).
to_cell_coords :: proc(pos: [2]f32) -> [2]i32 {
  return { i32(pos.x / F32_TILE_SIZE), i32(pos.y / F32_TILE_SIZE) }
}

// Get a generic value relative to the zoom (simple division)
relative_to_zoom :: proc(value: $T) -> f32 {
  return f32(value) / engine.camera.zoom
}

// Get current cell coords hovered by the mouse
get_current_hovered_cell_coords :: proc() -> [2]i32 {
  coords := to_cell_coords(rl.GetScreenToWorld2D(rl.GetMousePosition(), engine.camera))

  cap_coords(&coords)

  return coords
}

// Cap a given coords to the handle
cap_coords :: proc(coords: ^[2]i32) {
  coords.x = min(coords.x, _handle.cell_count_per_side)
  coords.x = max(coords.x, 0)
  coords.y = min(coords.y, _handle.cell_count_per_side)
  coords.y = max(coords.y, 0)
}

// Returns coords to tile index
coords_to_tile_index :: proc(coords: [2]i32) -> int {
  return int(coords[1] * _handle.cell_count_per_side + coords[0])
}

// Returns coords to chunk index
coords_to_chunk_index :: proc(coords: [2]i32) -> int {
  return int((coords[1] / CHUNK_SIZE) * _handle.chunks_per_side + coords[0] / CHUNK_SIZE)
}

// Returns chunk coords to chunk index
chunk_coords_to_chunk_index :: proc(coords: [2]i32) -> int {
  return int(coords[1] * _handle.chunks_per_side + coords[0])
}

// Returns coords to tile and chunk index
coords_to_tile_and_chunk_index :: proc(coords: [2]i32) -> (int, int) {
  return coords_to_tile_index(coords), coords_to_chunk_index(coords)
}

