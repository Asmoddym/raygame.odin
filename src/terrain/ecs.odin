package terrain

import "core:os"
import "core:math"
import "core:fmt"
import "../engine"
import "../lib/perlin_noise"
import rl "vendor:raylib"


// Main terrain component.
// Might be used with a different scale for minimap?
Component_Terrain :: struct {
  using base: engine.Component(engine.Metadata),
  handle: ^Handle,
  manipulation_state: ManipulationState,
}

table_terrains: engine.Table(Component_Terrain)


// PROCS


// Init terrain.
// No params for now but maybe later if I make it more generic
init :: proc() {
  tileset         := engine.assets_find_or_create(rl.Texture2D, "tileset/Tileset_Compressed_B_NoAnimation.png")
  component       := engine.database_add_component(engine.database_create_entity(), &table_terrains)
  component.handle = initialize_handle(10, tileset)
  component.manipulation_state = { {{ 0, 0 }, { 0, 0 }}, false, false, 0, { 0, 0 } }

  perlin_noise.repermutate(&component.handle.biome_noise_handle)
  perlin_noise.repermutate(&component.handle.default_noise_handle)

  for y in 0..<component.handle.size * CHUNK_SIZE {
    for x in 0..<component.handle.size * CHUNK_SIZE {
      idx := y * (component.handle.size * CHUNK_SIZE) + x

      component.handle.tiles[idx] = generate_terrain_cell(component.handle, x, y)
    }
  }

  for chunk_y in 0..<component.handle.size {
    for chunk_x in 0..<component.handle.size {
      idx := chunk_y * component.handle.size + chunk_x

      component.handle.display_chunks[idx] = generate_display_chunk(component.handle, chunk_x, chunk_y)
    }
  }
}

// Unload textures and free memory.
unload :: proc() {
  for &c in table_terrains.items {
    delete(c.handle.tiles)

    for &chunk in c.handle.display_chunks {
      rl.UnloadRenderTexture(chunk.render_texture)
    }

    delete(c.handle.display_chunks)
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

  handle    := table_terrains.items[0].handle
  drawn_rec := [2]rl.Vector2 {
    rl.GetScreenToWorld2D({ 0, 0 }, engine.camera),
    rl.GetScreenToWorld2D({ f32(engine.game_state.resolution.x), f32(engine.game_state.resolution.y) }, engine.camera),
  }

  drawn_rec[0] = { math.ceil(drawn_rec[0].x), math.round(drawn_rec[0].y) }
  drawn_rec[1] = { math.ceil(drawn_rec[1].x), math.round(drawn_rec[1].y) }

  for &c in handle.display_chunks {
    pos: [2]f32 = {
      f32(c.position.x * CHUNK_PIXEL_SIZE),
      f32(c.position.y * CHUNK_PIXEL_SIZE),
    }

    // If the chunks are not on draw range, we don't want them drawn
    chunk_presence_in_frame_x_check := pos.x >= drawn_rec[0].x - F32_CHUNK_PIXEL_SIZE && pos.x <= drawn_rec[1].x
    chunk_presence_in_frame_y_check := pos.y >= drawn_rec[0].y - F32_CHUNK_PIXEL_SIZE && pos.y <= drawn_rec[1].y

    if !(chunk_presence_in_frame_x_check && chunk_presence_in_frame_y_check) {
      continue
    }

    // Using this method to invert the texture as that's the way Raylib works
    rl.DrawTextureRec(
      c.render_texture.texture,
      rl.Rectangle { 0, 0,
        F32_CHUNK_PIXEL_SIZE,
        -F32_CHUNK_PIXEL_SIZE,
      },
      rl.Vector2 { pos.x, pos.y },
      rl.WHITE,
    )
  }
}

// Handle mouse inputs
system_mouse_inputs :: proc(terrain: ^Component_Terrain) {
  wheel_move := rl.GetMouseWheelMove()

  if wheel_move != 0 {
    terrain.manipulation_state.zoom_delta += wheel_move
  }

  if rl.IsMouseButtonDown(rl.MouseButton.LEFT) {
    delta := rl.GetMouseDelta()

    terrain.manipulation_state.target_delta.x -= relative_to_zoom(delta.x)
    terrain.manipulation_state.target_delta.y -= relative_to_zoom(delta.y)
  }

  if rl.IsMouseButtonPressed(rl.MouseButton.RIGHT) {
    terrain.manipulation_state.selecting = true
    terrain.manipulation_state.selection_finished = false
    terrain.manipulation_state.selection[0] = to_cell_coords({ rl.GetMouseX(), rl.GetMouseY() })
  }

  if terrain.manipulation_state.selecting {
    terrain.manipulation_state.selection[1] = to_cell_coords({ rl.GetMouseX(), rl.GetMouseY() })
  }

  if rl.IsMouseButtonReleased(rl.MouseButton.RIGHT) {
    terrain.manipulation_state.selecting = false
    terrain.manipulation_state.selection_finished = true
  }
}

// Handle keyboard inputs
system_keyboard_inputs :: proc(terrain: ^Component_Terrain) {
  time  := rl.GetFrameTime()
  value := relative_to_zoom(800 * time)

  if rl.IsKeyDown(rl.KeyboardKey.LEFT)  {
    terrain.manipulation_state.target_delta.x -= value
  }
  if rl.IsKeyDown(rl.KeyboardKey.RIGHT) {
    terrain.manipulation_state.target_delta.x += value
  }
  if rl.IsKeyDown(rl.KeyboardKey.UP)    {
    terrain.manipulation_state.target_delta.y -= value
  }
  if rl.IsKeyDown(rl.KeyboardKey.DOWN)  {
    terrain.manipulation_state.target_delta.y += value
  }
}
