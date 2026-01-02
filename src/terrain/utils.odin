package terrain

import "../engine"

// Returns given position, regardless of zoom and camera offsets, to its currently hovered cell position.
//
// /!\ This doesn't return the cell x and y coords, but the actual position (aka multiples of cell dimensions), like (16, 32).
to_cell_position :: proc(pos: [2]i32) -> [2]i32 {
  relative_position: [2]i32 = {
    i32(relative_to_zoom(pos.x - i32(engine.camera.offset.x)) + engine.camera.target.x),
    i32(relative_to_zoom(pos.y - i32(engine.camera.offset.y)) + engine.camera.target.y),
  }

  return { CELL_SIZE * (relative_position.x / CELL_SIZE), CELL_SIZE * (relative_position.y / CELL_SIZE) }
}

relative_to_zoom :: proc(value: $T) -> f32 {
  return f32(value) * 1 / engine.camera.zoom
}
