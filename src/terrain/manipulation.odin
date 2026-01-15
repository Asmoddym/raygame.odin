package terrain

import "core:fmt"
import "core:slice"
import rl "vendor:raylib"
import "../ui"
import "../engine"

ManipulationState :: struct {
  selection: [2][2]i32,
  selecting: bool,
  selection_finished: bool,

  zoom_delta: f32,
  target_delta: [2]f32,
}

// Different states processing with camera handling.
process_manipulation_state :: proc(terrain: ^Component_Terrain) {
  if terrain.manipulation_state.target_delta.x != 0 || terrain.manipulation_state.target_delta.y != 0 {
    ensure_camera_capped(terrain)
    terrain.manipulation_state.target_delta = { 0, 0 }
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
  handle    := terrain.handle
  selection := terrain.manipulation_state.selection

  first_point: [2]i32 = { min(selection[0].x, selection[1].x), min(selection[0].y, selection[1].y) }
  last_point: [2]i32 = { max(selection[0].x, selection[1].x), max(selection[0].y, selection[1].y) }
  // first_point[0] *= CELL_SIZE
  // first_point[1] *= CELL_SIZE
  // last_point[0] *= CELL_SIZE
  // last_point[1] *= CELL_SIZE

  first_point.x = min(first_point.x, handle.chunk_size.x * max_chunks_per_line)
  first_point.x = max(first_point.x, 0)
  first_point.y = min(first_point.y, handle.chunk_size.y * max_chunks_per_line)
  first_point.y = max(first_point.y, 0)
  last_point.x = min(last_point.x, handle.chunk_size.x * max_chunks_per_line)
  last_point.x = max(last_point.x, 0)
  last_point.y = min(last_point.y, handle.chunk_size.y * max_chunks_per_line)
  last_point.y = max(last_point.y, 0)

  fmt.println(first_point, last_point)
  for y in first_point.y..<last_point.y {
    for x in first_point.x..<last_point.x {
      // chunk_x := (x / handle.chunk_size.x) / CELL_SIZE
      // chunk_y := (y / handle.chunk_size.y) / CELL_SIZE
      // chunk_terrain_x := (x / CELL_SIZE) % handle.chunk_size.x
      // chunk_terrain_y := (y / CELL_SIZE) % handle.chunk_size.y
      //
      // handle.chunks[chunk_y * i32(max_chunks_per_line) + chunk_x].terrain[chunk_terrain_y][chunk_terrain_x].tileset_pos = { 0, 0 }
      // fmt.println(y * (50 * i32(max_chunks_per_line)) + x)
      idx := (y) * (max_chunks_per_line * handle.chunk_size.y) + x
      handle.tiles[idx].tileset_pos = { 0, 0 }
    }
  }

  rl.EndMode2D()
  for chunk_y in (first_point.y / handle.chunk_size.y)..=(last_point.y / handle.chunk_size.y) {
    for chunk_x in (first_point.x / handle.chunk_size.x)..=(last_point.x / handle.chunk_size.x) {
      idx: int = int(chunk_y * i32(max_chunks_per_line) + chunk_x)
      draw_display_chunk(handle, &handle.display_chunks[idx])
    }
  }
  rl.BeginMode2D(engine.camera)
}


// CAMERA


// Ensure zoom is capped.
@(private="file")
ensure_zoom_capped :: proc(terrain: ^Component_Terrain) {
  engine.camera.zoom += terrain.manipulation_state.zoom_delta * ZOOM_SPEED
  engine.camera.zoom = min(ZOOM_INTERVAL[1], engine.camera.zoom)
  engine.camera.zoom = max(ZOOM_INTERVAL[0], engine.camera.zoom)

  first_point := rl.GetWorldToScreen2D({ 0, 0 }, engine.camera)
  last_point := rl.GetWorldToScreen2D({ f32(terrain.handle.chunk_pixel_size.x * max_chunks_per_line), f32(terrain.handle.chunk_pixel_size.y * max_chunks_per_line) }, engine.camera)

  too_zoomed_x := last_point.x - first_point.x < f32(engine.game_state.resolution.x)
  too_zoomed_y := last_point.y - first_point.y < f32(engine.game_state.resolution.y)

  if too_zoomed_x || too_zoomed_y {
    engine.camera.zoom = f32(engine.game_state.resolution.x) / f32(terrain.handle.chunk_pixel_size.x * max_chunks_per_line)
  }

  ensure_camera_capped(terrain)
}

// Ensure camera is in frame
@(private="file")
ensure_camera_capped :: proc(terrain: ^Component_Terrain) {
  // I can't use GetWorldToScreen2D because the result would move as I'm scrolling
  first_point := rl.Vector2 {
    engine.camera.offset.x / engine.camera.zoom,
    engine.camera.offset.y / engine.camera.zoom,
  }

  last_point := rl.Vector2 {
    (f32(terrain.handle.chunk_pixel_size.x * max_chunks_per_line) + first_point.x) - f32(engine.game_state.resolution.x) / engine.camera.zoom,
    (f32(terrain.handle.chunk_pixel_size.y * max_chunks_per_line) + first_point.y) - f32(engine.game_state.resolution.y) / engine.camera.zoom,
  }

  engine.camera.target.x += terrain.manipulation_state.target_delta.x
  engine.camera.target.x = max(first_point.x, engine.camera.target.x)
  engine.camera.target.x = min(last_point.x, engine.camera.target.x)

  engine.camera.target.y += terrain.manipulation_state.target_delta.y
  engine.camera.target.y = max(first_point.y, engine.camera.target.y)
  engine.camera.target.y = min(last_point.y, engine.camera.target.y)
}


// MOUSE / SELECTION DRAWING


// Draw selection when in select mode.
@(private="file")
draw_selection :: proc(terrain: ^Component_Terrain) {
  first_point: [2]i32 = { min(terrain.manipulation_state.selection[0].x, terrain.manipulation_state.selection[1].x), min(terrain.manipulation_state.selection[0].y, terrain.manipulation_state.selection[1].y) }
  last_point: [2]i32 = { max(terrain.manipulation_state.selection[0].x, terrain.manipulation_state.selection[1].x), max(terrain.manipulation_state.selection[0].y, terrain.manipulation_state.selection[1].y) }

  first_point[0] *= CELL_SIZE
  first_point[1] *= CELL_SIZE
  last_point[0] *= CELL_SIZE
  last_point[1] *= CELL_SIZE

  text := string(rl.TextFormat("%dx%d", abs(last_point.x - first_point.x) / CELL_SIZE, abs(last_point.y - first_point.y) / CELL_SIZE))
  ui.text_box_draw_fast(text, last_point.x, last_point.y, i32(relative_to_zoom(18)))

  rl.DrawRectangle(first_point.x, first_point.y, last_point.x - first_point.x, last_point.y - first_point.y, rl.Color { 255, 0, 0, 100 })
}

// Draw hovered cell when not in select mode.
@(private="file")
draw_hover :: proc(terrain: ^Component_Terrain) {
  mouse_pos := to_cell_coords({ rl.GetMouseX(), rl.GetMouseY() })

  rl.DrawRectangle(mouse_pos.x * CELL_SIZE, mouse_pos.y * CELL_SIZE, CELL_SIZE, CELL_SIZE, rl.Color { 255, 0, 0, 100 })
}
