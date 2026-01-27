
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
  } else {
    draw_hover()
  }

  delta := rl.GetMouseDelta()

  if delta.x != 0 || delta.y != 0 {
    first_point, last_point := get_current_hovered_zone_to_cell_coords()

    for y in first_point.y..<last_point.y {
      for x in first_point.x..<last_point.x {
        idx := y * _handle.cell_count_per_side + x

        _handle.tiles[idx].discovered = true
      }
    }

    rl.EndMode2D()
    for chunk_y in (first_point.y / CHUNK_SIZE)..=(last_point.y / CHUNK_SIZE) {
      for chunk_x in (first_point.x / CHUNK_SIZE)..=(last_point.x / CHUNK_SIZE) {
        idx: int = int(chunk_y * _handle.chunks_per_side + chunk_x)
        if idx >= len(_handle.display_chunks) do continue

        draw_mask_chunk(&_handle.display_chunks[idx])
      }
    }
    rl.BeginMode2D(engine.camera)
  }
}


// PRIVATE



// Process the selection with selection is complete
@(private="file")
process_selection :: proc() {
  first_point: [2]i32 = { min(selection.rec[0].x, selection.rec[1].x), min(selection.rec[0].y, selection.rec[1].y) }
  last_point: [2]i32 = { max(selection.rec[0].x, selection.rec[1].x), max(selection.rec[0].y, selection.rec[1].y) }

  first_point.x = min(first_point.x, _handle.cell_count_per_side)
  first_point.x = max(first_point.x, 0)
  first_point.y = min(first_point.y, _handle.cell_count_per_side)
  first_point.y = max(first_point.y, 0)
  last_point.x = min(last_point.x, _handle.cell_count_per_side)
  last_point.x = max(last_point.x, 0)
  last_point.y = min(last_point.y, _handle.cell_count_per_side)
  last_point.y = max(last_point.y, 0)

  for y in first_point.y..<last_point.y {
    for x in first_point.x..<last_point.x {
      idx := y * _handle.cell_count_per_side + x

      _handle.tiles[idx].tileset_pos = { 0, 0 }
    }
  }

  rl.EndMode2D()
  for chunk_y in (first_point.y / CHUNK_SIZE)..=(last_point.y / CHUNK_SIZE) {
    for chunk_x in (first_point.x / CHUNK_SIZE)..=(last_point.x / CHUNK_SIZE) {
      idx: int = int(chunk_y * _handle.chunks_per_side + chunk_x)
      if idx >= len(_handle.display_chunks) do continue

      draw_display_chunk(&_handle.display_chunks[idx])
    }
  }
  rl.BeginMode2D(engine.camera)
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

// Draw hovered cell when not in select mode.
@(private="file")
draw_hover :: proc() {
  mouse_pos := to_cell_coords(rl.GetScreenToWorld2D(rl.GetMousePosition(), engine.camera))

  rl.DrawRectangle(mouse_pos.x * TILE_SIZE, mouse_pos.y * TILE_SIZE, TILE_SIZE, TILE_SIZE, rl.Color { 255, 0, 0, 100 })
}
