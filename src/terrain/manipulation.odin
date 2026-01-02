package terrain

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
}

// manipulation_state: ManipulationState = {  false, false }

process_manipulation_state :: proc(terrain: ^Component_Terrain) {
  if terrain.manipulation_state.camera_changed {
    ensure_camera_capped(&terrain.handle)
    terrain.manipulation_state.camera_changed = false
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



// Ensure camera is in frame
@(private="file")
ensure_camera_capped :: proc(handle: ^Handle) {
  max_x := f32(handle.chunk_size.x * int(handle.displayed_tile_size)) * f32(max_chunks_per_line) - relative_to_zoom(engine.game_state.resolution.x)
  max_y := f32(handle.chunk_size.y * int(handle.displayed_tile_size)) * f32(max_chunks_per_line) - relative_to_zoom(engine.game_state.resolution.y)

  if engine.camera.target.x < 0 do engine.camera.target.x = 0
  if engine.camera.target.y < 0 do engine.camera.target.y = 0

  if engine.camera.target.x > max_x do engine.camera.target.x = max_x
  if engine.camera.target.y > max_y do engine.camera.target.y = max_y
}

process_selection :: proc(terrain: ^Component_Terrain) {
  handle    := &terrain.handle
  selection := terrain.manipulation_state.selection

  first_point: [2]i32 = { min(selection[0].x, selection[1].x), min(selection[0].y, selection[1].y) }
  last_point: [2]i32 = { max(selection[0].x, selection[1].x), max(selection[0].y, selection[1].y) }

  chunks_to_redraw: [dynamic]^Chunk

  for y in first_point.y..<last_point.y {
    for x in first_point.x..<last_point.x {
      chunk_x := int((x / i32(handle.chunk_size.x)) / CELL_SIZE)
      chunk_y := int((y / i32(handle.chunk_size.y)) / CELL_SIZE)
      chunk_terrain_x := int(x / CELL_SIZE) % handle.chunk_size.x
      chunk_terrain_y := int(y / CELL_SIZE) % handle.chunk_size.y

      chunk: ^Chunk = nil

      for &c in handle.chunks {
        if c.position.x == chunk_x && c.position.y == chunk_y {
          chunk = &c

          chunk.terrain[chunk_terrain_y][chunk_terrain_x].tileset_pos = { 0, 0 }
          context.user_ptr = &c

          _, found := slice.linear_search_proc(chunks_to_redraw[:], proc(p: ^Chunk) -> bool {
            chunk: ^Chunk = cast(^Chunk)context.user_ptr

            return p.position.x == chunk.position.x && p.position.y == chunk.position.y
          })

          if !found {
            append(&chunks_to_redraw, &c)
          }
        }
      }
    }
  }

  rl.EndMode2D()
  for &chunk in chunks_to_redraw {
    draw_chunk(handle, chunk)
  }
  rl.BeginMode2D(engine.camera)
}

draw_selection :: proc(terrain: ^Component_Terrain) {
  first_point: [2]i32 = { min(terrain.manipulation_state.selection[0].x, terrain.manipulation_state.selection[1].x), min(terrain.manipulation_state.selection[0].y, terrain.manipulation_state.selection[1].y) }
  last_point: [2]i32 = { max(terrain.manipulation_state.selection[0].x, terrain.manipulation_state.selection[1].x), max(terrain.manipulation_state.selection[0].y, terrain.manipulation_state.selection[1].y) }

  text := string(rl.TextFormat("%dx%d", abs(last_point.x - first_point.x) / CELL_SIZE, abs(last_point.y - first_point.y) / CELL_SIZE))
  ui.text_box_draw_fast(text, first_point.x, first_point.y, i32(relative_to_zoom(18)))

  rl.DrawRectangle(first_point.x, first_point.y, last_point.x - first_point.x, last_point.y - first_point.y, rl.Color { 255, 0, 0, 100 })
}

draw_hover :: proc(terrain: ^Component_Terrain) {
  mouse_pos := to_cell_position({ rl.GetMouseX(), rl.GetMouseY() })

  rl.DrawRectangle(mouse_pos.x, mouse_pos.y, CELL_SIZE, CELL_SIZE, rl.Color { 255, 0, 0, 100 })
}
