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
  component.handle = initialize_handle(50, 50, tileset)
  component.manipulation_state = { {{ 0, 0 }, { 0, 0 }}, false, false, 0, { 0, 0 } }

  perlin_noise.repermutate(&component.handle.biome_noise_handle)
  perlin_noise.repermutate(&component.handle.default_noise_handle)

  for y in 0..<max_chunks_per_line * 50 {
    for x in 0..<max_chunks_per_line * 50 {
      component.handle.tiles[y * (max_chunks_per_line * 50) + x] = generate_terrain_cell(component.handle, x, y)
    }
  }

  for chunk_y: i32 = 0; chunk_y < max_chunks_per_line * 50; chunk_y += 50 {
    for chunk_x: i32 = 0; chunk_x < max_chunks_per_line * 50; chunk_x += 50 {
      append(&component.handle.display_chunks, generate_display_chunk(component.handle, chunk_x, chunk_y))
    }
  }
}

// Unload textures and free memory.
unload :: proc() {
  for &c in table_terrains.items {
    delete(c.handle.tiles)
  }
  //   for &chunk in c.handle.chunks {
  //     rl.UnloadRenderTexture(chunk.render_texture)
  //     for &line in chunk.terrain {
  //       delete(line)
  //     }
  //     delete(chunk.terrain)
  //   }
  //   delete(c.handle.chunks)
  // }
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
      f32(c.position.x * handle.tile_size),
      f32(c.position.y * handle.tile_size),
    }

    // If the chunks are not on draw range, we don't want them drawn
    chunk_presence_in_frame_x_check := pos.x >= drawn_rec[0].x - f32(handle.chunk_pixel_size.x) && pos.x <= drawn_rec[1].x
    chunk_presence_in_frame_y_check := pos.y >= drawn_rec[0].y - f32(handle.chunk_pixel_size.y) && pos.y <= drawn_rec[1].y

    if !(chunk_presence_in_frame_x_check && chunk_presence_in_frame_y_check) {
      continue
    }

    // fmt.println(pos, drawn_rec)

    // Using this method to invert the texture as that's the way Raylib works
    rl.DrawTextureRec(
      c.render_texture.texture,
      rl.Rectangle { 0, 0,
        f32(handle.chunk_pixel_size.x),
        f32(-handle.chunk_pixel_size.y),
      },
      rl.Vector2 { pos.x, pos.y },
      rl.WHITE,
    )

  // for &t in handle.tiles {
  //   pos: [2]f32 = {
  //     f32(t.position.x * handle.displayed_tile_size),
  //     f32(t.position.y * handle.displayed_tile_size),
  //   }
  //
  //   // If the chunks are not on draw range, we don't want them drawn
  //   chunk_presence_in_frame_x_check := pos.x >= drawn_rec[0].x - f32(handle.chunk_pixel_size.x) && pos.x <= drawn_rec[1].x
  //   chunk_presence_in_frame_y_check := pos.y >= drawn_rec[0].y - f32(handle.chunk_pixel_size.y) && pos.y <= drawn_rec[1].y
  //
  //  if !(chunk_presence_in_frame_x_check && chunk_presence_in_frame_y_check) {
  //     continue
  //   }
  //
  //     source := rl.Rectangle {
  //       f32(t.tileset_pos.x) * f32(handle.tile_size),
  //       f32(t.tileset_pos.y) * f32(handle.tile_size),
  //       f32(handle.tile_size),
  //       f32(handle.tile_size),
  //     }
  //
  //     dest := rl.Rectangle {
  //       f32(t.position.x * handle.displayed_tile_size),
  //       f32(t.position.y * handle.displayed_tile_size),
  //       f32(handle.displayed_tile_size),
  //       f32(handle.displayed_tile_size),
  //     }
  //
  //     rl.DrawTexturePro(handle.tileset, source, dest, { 0, 0 }, 0, rl.WHITE)

  // rl.DrawText(rl.TextFormat("%d,%d", t.position.x, t.position.y), 
  //       i32(t.position.x * handle.displayed_tile_size),
  //       i32(t.position.y * handle.displayed_tile_size), 6, rl.WHITE)

  // Using this method to invert the texture as that's the way Raylib works
    // rl.DrawTextureRec(
    //   c.render_texture.texture,
    //   rl.Rectangle { 0, 0,
    //     f32(handle.chunk_pixel_size.x),
    //     f32(-handle.chunk_pixel_size.y),
    //   },
    //   rl.Vector2 { pos.x, pos.y },
    //   rl.WHITE,
    // )
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
