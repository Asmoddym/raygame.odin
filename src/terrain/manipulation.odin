package terrain

import "core:fmt"
import "core:slice"
import rl "vendor:raylib"
import "../ui"
import "../engine"

ManipulationState :: struct {
  selection: [2][2]i32,
  selection_text: string,
  selecting: bool,
  selection_finished: bool,

  camera_changed: bool,

  zoom_delta: f32,
}

// Different states processing with camera handling.
process_manipulation_state :: proc(terrain: ^Component_Terrain) {
  if terrain.manipulation_state.camera_changed {
    ensure_camera_capped(&terrain.handle)
    terrain.manipulation_state.camera_changed = false
  }

  if terrain.manipulation_state.zoom_delta != 0 {
    ensure_zoom_capped(terrain)
    terrain.manipulation_state.zoom_delta = 0
  }

  if terrain.manipulation_state.selection_finished {
    process_selection(terrain)
    terrain.manipulation_state.selection_finished = false
  }

  if terrain.manipulation_state.selecting {
    draw_selection(terrain)
  } else {
    draw_hover(terrain)
  }
}



//
// PRIVATE
//



// Process the selection with selection is complete
@(private="file")
process_selection :: proc(terrain: ^Component_Terrain) {
  handle    := &terrain.handle
  selection := terrain.manipulation_state.selection

  first_point: [2]i32 = { min(selection[0].x, selection[1].x), min(selection[0].y, selection[1].y) }
  last_point: [2]i32 = { max(selection[0].x, selection[1].x), max(selection[0].y, selection[1].y) }

  first_point.x = min(first_point.x, handle.chunk_size.x * max_chunks_per_line * CELL_SIZE)
  first_point.x = max(first_point.x, 0)
  first_point.y = min(first_point.y, handle.chunk_size.y * max_chunks_per_line * CELL_SIZE)
  first_point.y = max(first_point.y, 0)
  last_point.x = min(last_point.x, handle.chunk_size.x * max_chunks_per_line * CELL_SIZE)
  last_point.x = max(last_point.x, 0)
  last_point.y = min(last_point.y, handle.chunk_size.y * max_chunks_per_line * CELL_SIZE)
  last_point.y = max(last_point.y, 0)

  for y in first_point.y..<last_point.y {
    for x in first_point.x..<last_point.x {
      chunk_x := (x / handle.chunk_size.x) / CELL_SIZE
      chunk_y := (y / handle.chunk_size.y) / CELL_SIZE
      chunk_terrain_x := (x / CELL_SIZE) % handle.chunk_size.x
      chunk_terrain_y := (y / CELL_SIZE) % handle.chunk_size.y

      handle.chunks[chunk_y * i32(max_chunks_per_line) + chunk_x].terrain[chunk_terrain_y][chunk_terrain_x].tileset_pos = { 0, 0 }
    }
  }

  rl.EndMode2D()
  for chunk_y in (first_point.y / handle.chunk_size.y) / CELL_SIZE..=(last_point.y / handle.chunk_size.y) / CELL_SIZE {
    for chunk_x in (first_point.x / handle.chunk_size.x) / CELL_SIZE..=(last_point.x / handle.chunk_size.x) / CELL_SIZE {
      idx: int = int(chunk_y * i32(max_chunks_per_line) + chunk_x)

      if idx < len(handle.chunks) do draw_chunk(handle, &handle.chunks[idx])
    }
  }
  rl.BeginMode2D(engine.camera)
}


// CAMERA


// Ensure zoom is capped.
@(private="file")
ensure_zoom_capped :: proc(terrain: ^Component_Terrain) {
  new_zoom := engine.camera.zoom + terrain.manipulation_state.zoom_delta * ZOOM_SPEED

  max_x := f32(terrain.handle.chunk_size.x * terrain.handle.displayed_tile_size) * f32(max_chunks_per_line)
  max_y := f32(terrain.handle.chunk_size.y * terrain.handle.displayed_tile_size) * f32(max_chunks_per_line)

  x_check := f32(engine.game_state.resolution.x) * 1 / (new_zoom + ZOOM_SPEED) < max_x
  y_check := f32(engine.game_state.resolution.y) * 1 / (new_zoom + ZOOM_SPEED) < max_y

  if x_check && y_check {
    engine.camera.zoom = new_zoom
    engine.camera.zoom = min(ZOOM_INTERVAL[1], engine.camera.zoom)
    engine.camera.zoom = max(ZOOM_INTERVAL[0], engine.camera.zoom)
  }

  ensure_camera_capped(&terrain.handle)
}

// Ensure camera is in frame
@(private="file")
ensure_camera_capped :: proc(handle: ^Handle) {
  relative_offset_x := relative_to_zoom(engine.camera.offset.x)
  relative_offset_y := relative_to_zoom(engine.camera.offset.y)

  threshold_x: f32 = f32(engine.game_state.resolution.x) / 2
  threshold_y: f32 = f32(engine.game_state.resolution.y) / 2

  x := engine.camera.target.x - relative_offset_x
  y := engine.camera.target.y - relative_offset_y

  max_x := f32(handle.chunk_size.x * handle.displayed_tile_size) * f32(max_chunks_per_line) - relative_to_zoom(engine.game_state.resolution.x / 2) - relative_offset_x
  max_y := f32(handle.chunk_size.y * handle.displayed_tile_size) * f32(max_chunks_per_line) - relative_to_zoom(engine.game_state.resolution.y / 2) - relative_offset_y

  if x < -threshold_x do engine.camera.target.x = relative_offset_x - threshold_x
  if y < -threshold_y do engine.camera.target.y = relative_offset_y - threshold_y

  if x > max_x + threshold_x do engine.camera.target.x = max_x + relative_offset_x + threshold_x
  if y > max_y + threshold_y do engine.camera.target.y = max_y + relative_offset_y + threshold_y
}


// MOUSE / SELECTION DRAWING


// Draw selection when in select mode.
@(private="file")
draw_selection :: proc(terrain: ^Component_Terrain) {
  first_point: [2]i32 = { min(terrain.manipulation_state.selection[0].x, terrain.manipulation_state.selection[1].x), min(terrain.manipulation_state.selection[0].y, terrain.manipulation_state.selection[1].y) }
  last_point: [2]i32 = { max(terrain.manipulation_state.selection[0].x, terrain.manipulation_state.selection[1].x), max(terrain.manipulation_state.selection[0].y, terrain.manipulation_state.selection[1].y) }

  text := string(rl.TextFormat("%dx%d", abs(last_point.x - first_point.x) / CELL_SIZE, abs(last_point.y - first_point.y) / CELL_SIZE))
  ui.text_box_draw_fast(text, last_point.x, last_point.y, i32(relative_to_zoom(18)))

  rl.DrawRectangle(first_point.x, first_point.y, last_point.x - first_point.x, last_point.y - first_point.y, rl.Color { 255, 0, 0, 100 })
}

// Draw hovered cell when not in select mode.
@(private="file")
draw_hover :: proc(terrain: ^Component_Terrain) {
  mouse_pos := to_cell_position({ rl.GetMouseX(), rl.GetMouseY() })

  rl.DrawRectangle(mouse_pos.x, mouse_pos.y, CELL_SIZE, CELL_SIZE, rl.Color { 255, 0, 0, 100 })
}
