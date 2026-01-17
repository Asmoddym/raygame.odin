package terrain

import "core:fmt"
import "../engine"
import rl "vendor:raylib"

// Terrain state struct
ManipulationState :: struct {
  selection: [2][2]i32,
  selecting: bool,
  selection_finished: bool,

  zoom_delta: f32,
  target_delta: [2]f32,
}


// Main manipulation system (scroll, zoom, selection).
process_inputs :: proc() {
  system_mouse_inputs()
  system_keyboard_inputs()

  process_manipulation_state()
}


// Different states processing with camera handling.
@(private="file")
process_manipulation_state :: proc() {
  if _manipulation_state.target_delta.x != 0 || _manipulation_state.target_delta.y != 0 {
    ensure_camera_capped()
    _manipulation_state.target_delta = { 0, 0 }
  }

  if _manipulation_state.zoom_delta != 0 {
    ensure_zoom_capped()
    _manipulation_state.zoom_delta = 0
  }

  if _manipulation_state.selection_finished {
    process_selection()
    _manipulation_state.selection_finished = false
  }
}

// Handle mouse inputs
@(private="file")
system_mouse_inputs :: proc() {
  wheel_move := rl.GetMouseWheelMove()

  if wheel_move != 0 {
    _manipulation_state.zoom_delta += wheel_move
  }

  if rl.IsMouseButtonDown(rl.MouseButton.LEFT) {
    delta := rl.GetMouseDelta()

    _manipulation_state.target_delta.x -= delta.x
    _manipulation_state.target_delta.y -= delta.y
  }

  if rl.IsMouseButtonPressed(rl.MouseButton.RIGHT) {
    _manipulation_state.selecting = true
    _manipulation_state.selection_finished = false
    _manipulation_state.selection[0] = to_cell_coords(rl.GetScreenToWorld2D(rl.GetMousePosition(), engine.camera))
  }

  if _manipulation_state.selecting {
    _manipulation_state.selection[1] = to_cell_coords(rl.GetScreenToWorld2D(rl.GetMousePosition(), engine.camera))
  }

  if rl.IsMouseButtonReleased(rl.MouseButton.RIGHT) {
    _manipulation_state.selecting = false
    _manipulation_state.selection_finished = true
  }
}

// Handle keyboard inputs
@(private="file")
system_keyboard_inputs :: proc() {
  time  := rl.GetFrameTime()
  value := relative_to_zoom(800 * time)

  if rl.IsKeyDown(rl.KeyboardKey.LEFT)  {
    _manipulation_state.target_delta.x -= value
  }
  if rl.IsKeyDown(rl.KeyboardKey.RIGHT) {
    _manipulation_state.target_delta.x += value
  }
  if rl.IsKeyDown(rl.KeyboardKey.UP)    {
    _manipulation_state.target_delta.y -= value
  }
  if rl.IsKeyDown(rl.KeyboardKey.DOWN)  {
    _manipulation_state.target_delta.y += value
  }
}

// Process the selection with selection is complete
@(private="file")
process_selection :: proc() {
  selection := _manipulation_state.selection

  first_point: [2]i32 = { min(selection[0].x, selection[1].x), min(selection[0].y, selection[1].y) }
  last_point: [2]i32 = { max(selection[0].x, selection[1].x), max(selection[0].y, selection[1].y) }

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


// GLOBALS


_manipulation_state: ManipulationState
