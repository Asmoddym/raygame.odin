package terrain

import "core:fmt"
import "../engine"
import "../lib/perlin_noise"
import rl "vendor:raylib"


// Main terrain component.
// Might be used with a different scale for minimap?
Component_Terrain :: struct {
  using base: engine.Component(engine.Metadata),
  handle: Handle,
  manipulation_state: ManipulationState,
}

table_terrains: engine.Table(Component_Terrain)


// PROCS


// Init terrain.
// No params for now but maybe later if I make it more generic
init :: proc() {
  tileset         := engine.assets_find_or_create(rl.Texture2D, "tileset/Tileset_Compressed_B_NoAnimation.png")
  component       := engine.database_add_component(engine.database_create_entity(), &table_terrains)
  component.handle = initialize_handle(50, 50, tileset)
  component.manipulation_state = { {{ 0, 0 }, { 0, 0 }}, "", false, false, false, 0 }

  perlin_noise.repermutate(&component.handle.biome_noise_handle)
  perlin_noise.repermutate(&component.handle.default_noise_handle)

  for y in 0..<max_chunks_per_line {
    for x in 0..<max_chunks_per_line {
      generate_chunk(&component.handle, x, y)
    }
  }
}


// SYSTEMS


// Main manipulation system (scroll, zoom, selection).
system_manipulation :: proc() {
  if len(table_terrains.items) == 0 do return

  c := &table_terrains.items[0]

  system_mouse_inputs(c)
  system_keyboard_inputs(c)

  process_manipulation_state(c)
}

// Main draw system.
system_draw :: proc() {
  if len(table_terrains.items) == 0 do return
    drawn_rec := engine.get_drawn_frame_rec()
    handle    := &table_terrains.items[0].handle

  for &c in handle.chunks {
    pos: [2]f32 = {
      f32(c.position.x * handle.chunk_pixel_size.x),
      f32(c.position.y * handle.chunk_pixel_size.y),
    }

    if pos.x < drawn_rec[0].x - f32(handle.chunk_pixel_size.x) || pos.x > drawn_rec[1].x {
      continue
    }

    if pos.y < drawn_rec[0].y - f32(handle.chunk_pixel_size.y) || pos.y > drawn_rec[1].y {
      continue
    }

    // Using this method to invert the texture as that's the way Raylib works
    rl.DrawTextureRec(
      c.render_texture.texture,
      rl.Rectangle { 0, 0,
        f32(handle.chunk_size.x * int(handle.displayed_tile_size)),
        -f32(handle.chunk_size.y * int(handle.displayed_tile_size)),
      },
      rl.Vector2 { pos.x, pos.y },
      rl.WHITE,
    )
  }
}

// Handle mouse inputs
system_mouse_inputs :: proc(terrain: ^Component_Terrain) {
  wheel_move := rl.GetMouseWheelMove()

  if wheel_move != 0 { //&& (engine.camera.zoom >= ZOOM_INTERVAL.x && engine.camera.zoom <= ZOOM_INTERVAL.y) {
    terrain.manipulation_state.zoom_delta += wheel_move * ZOOM_SPEED
  }

  if rl.IsMouseButtonDown(rl.MouseButton.LEFT) {
    delta := rl.GetMouseDelta()

    engine.camera.target.x -= relative_to_zoom(delta.x)
    engine.camera.target.y -= relative_to_zoom(delta.y)

    terrain.manipulation_state.camera_changed = true
  }

  if rl.IsMouseButtonPressed(rl.MouseButton.RIGHT) {
    terrain.manipulation_state.selecting = true
    terrain.manipulation_state.selection_finished = false
    terrain.manipulation_state.selection[0] = to_cell_position({ rl.GetMouseX(), rl.GetMouseY() })
  }

  if terrain.manipulation_state.selecting {
    terrain.manipulation_state.selection[1] = to_cell_position({ rl.GetMouseX(), rl.GetMouseY() })
  }

  if rl.IsMouseButtonReleased(rl.MouseButton.RIGHT) {
    terrain.manipulation_state.selecting = false
    terrain.manipulation_state.selection_finished = true
  }

  // cap_camera(handle)

  // relative_x := engine.game_state.resolution.x - i32(rl.GetMouseX())
  // relative_y := engine.game_state.resolution.y - i32(rl.GetMouseY())

  // if relative_x < BORDER_OFFSET {
  //   engine.camera.target.x += 800 * time
  // } else if relative_x > engine.game_state.resolution.x - BORDER_OFFSET {
  //   engine.camera.target.x -= 800 * time
  // }
  //
  // if relative_y < BORDER_OFFSET {
  //   engine.camera.target.y += 800 * time
  // } else if relative_y > engine.game_state.resolution.y - BORDER_OFFSET {
  //   engine.camera.target.y -= 800 * time
  // }
  //
}

// Handle keyboard inputs
system_keyboard_inputs :: proc(terrain: ^Component_Terrain) {
  time  := rl.GetFrameTime()
  value := relative_to_zoom(800 * time)

  if rl.IsKeyDown(rl.KeyboardKey.LEFT)  do engine.camera.target.x -= value
  if rl.IsKeyDown(rl.KeyboardKey.RIGHT) do engine.camera.target.x += value
  if rl.IsKeyDown(rl.KeyboardKey.UP)    do engine.camera.target.y -= value
  if rl.IsKeyDown(rl.KeyboardKey.DOWN)  do engine.camera.target.y += value

  terrain.manipulation_state.camera_changed = true
}
