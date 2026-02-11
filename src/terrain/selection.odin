
package terrain

import "../engine"
import "../ui"
import rl "vendor:raylib"


// GLOBALS


selection: SelectionState



// PROCS


// Main manipulation system (scroll, zoom, selection).
process_selection :: proc() {
  if rl.IsMouseButtonPressed(rl.MouseButton.RIGHT) {
    selection.selecting = true
    selection.selection_finished = false
    selection.rec[0] = to_cell_coords(rl.GetScreenToWorld2D(rl.GetMousePosition(), engine.camera))
  }

  if selection.selecting {
    selection.rec[1] = to_cell_coords(rl.GetScreenToWorld2D(rl.GetMousePosition(), engine.camera))
  }

  if rl.IsMouseButtonReleased(rl.MouseButton.RIGHT) {
    selection.selecting = false
    process_selection()
  }

  if selection.selecting {
    draw_selection()
  }
}


// PRIVATE



// Process the selection with selection is complete
@(private="file")
process_selection :: proc() {
  first_point: [2]i32 = { min(selection.rec[0].x, selection.rec[1].x), min(selection.rec[0].y, selection.rec[1].y) }
  last_point: [2]i32 = { max(selection.rec[0].x, selection.rec[1].x), max(selection.rec[0].y, selection.rec[1].y) }

  cap_coords(&first_point)
  cap_coords(&last_point)

  for y in first_point.y..<last_point.y {
    for x in first_point.x..<last_point.x {
      _handle.tiles[coords_to_tile_index({ x, y })].tileset_pos = { 0, 0 }
    }
  }

  for chunk_y in (first_point.y / CHUNK_SIZE)..=(last_point.y / CHUNK_SIZE) {
    for chunk_x in (first_point.x / CHUNK_SIZE)..=(last_point.x / CHUNK_SIZE) {
      idx := chunk_coords_to_chunk_index({ chunk_x, chunk_y })
      if idx >= len(_handle.display_chunks) do continue

      draw_display_chunk(&_handle.display_chunks[idx])
    }
  }
}



@(private="file")
SelectionState :: struct {
  rec: [2][2]i32,
  selecting: bool,
  selection_finished: bool,
}


// PROCS


// Draw selection when in select mode.
@(private="file")
draw_selection :: proc() {
  first_point: [2]i32 = { min(selection.rec[0].x, selection.rec[1].x), min(selection.rec[0].y, selection.rec[1].y) }
  last_point: [2]i32 = { max(selection.rec[0].x, selection.rec[1].x), max(selection.rec[0].y, selection.rec[1].y) }

  first_point[0] *= TILE_SIZE
  first_point[1] *= TILE_SIZE
  last_point[0] *= TILE_SIZE
  last_point[1] *= TILE_SIZE

  text := string(rl.TextFormat("%dx%d", abs(last_point.x - first_point.x) / TILE_SIZE, abs(last_point.y - first_point.y) / TILE_SIZE))
  ui.text_box_draw_fast(text, last_point.x, last_point.y, i32(relative_to_zoom(18)))

  rl.DrawRectangle(first_point.x, first_point.y, last_point.x - first_point.x, last_point.y - first_point.y, rl.Color { 255, 0, 0, 100 })
}
