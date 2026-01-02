package terrain

import "../engine"
import "../lib/perlin_noise"
import rl "vendor:raylib"


// Main terrain component.
// Might be used with a different scale for minimap?
Component_Terrain :: struct {
  using base: engine.Component(engine.Metadata),
  handle: Handle,
}

table_terrains: engine.Table(Component_Terrain)


// PROCS


// Init terrain.
// No params for now but maybe later if I make it more generic
init :: proc() {
  tileset         := engine.assets_find_or_create(rl.Texture2D, "tileset/Tileset_Compressed_B_NoAnimation.png")
  component       := engine.database_add_component(engine.database_create_entity(), &table_terrains)
  component.handle = initialize_handle(50, 50, tileset)

  perlin_noise.repermutate(&component.handle.biome_noise_handle)
  perlin_noise.repermutate(&component.handle.default_noise_handle)

  for y in 0..<max_chunks_per_line {
    for x in 0..<max_chunks_per_line {
      generate_chunk(&component.handle, x, y)
    }
  }
}


// SYSTEMS


// Main draw system.
system_draw :: proc() {
  if len(table_terrains.items) == 0 do return

  handle := &table_terrains.items[0].handle

  for &c in handle.chunks {
    // Using this method to invert the texture as that's the way Raylib works
    rl.DrawTextureRec(
      c.render_texture.texture,
      rl.Rectangle {
        0, 0,
        f32(handle.chunk_size.x * int(handle.displayed_tile_size)),
        -f32(handle.chunk_size.y * int(handle.displayed_tile_size)) },
        rl.Vector2 {
          f32(c.position.x * handle.chunk_size.x) * f32(handle.displayed_tile_size),
          f32(c.position.y * handle.chunk_size.y) * f32(handle.displayed_tile_size),
        },
        rl.WHITE,
    )
  }
}

// Handle mouse inputs
system_mouse_inputs :: proc() {
  if len(table_terrains.items) == 0 do return

  handle := &table_terrains.items[0].handle
  wheel_move := rl.GetMouseWheelMove()

  if wheel_move != 0 && (engine.camera.zoom >= ZOOM_INTERVAL.x && engine.camera.zoom <= ZOOM_INTERVAL.y) {
    engine.camera.zoom += wheel_move * ZOOM_SPEED

    engine.camera.zoom = min(ZOOM_INTERVAL.y, engine.camera.zoom)
    engine.camera.zoom = max(ZOOM_INTERVAL.x, engine.camera.zoom)
  }

  if rl.IsMouseButtonDown(rl.MouseButton.LEFT) {
    delta := rl.GetMouseDelta()

    engine.camera.target.x -= relative_to_zoom(delta.x)
    engine.camera.target.y -= relative_to_zoom(delta.y)
  }

  cap_camera(handle)

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
system_keyboard_inputs :: proc() {
  if len(table_terrains.items) == 0 do return

  handle := &table_terrains.items[0].handle
  time := rl.GetFrameTime()

  value := relative_to_zoom(800 * time)

  if rl.IsKeyDown(rl.KeyboardKey.LEFT)  do engine.camera.target.x -= value
  if rl.IsKeyDown(rl.KeyboardKey.RIGHT) do engine.camera.target.x += value
  if rl.IsKeyDown(rl.KeyboardKey.UP)    do engine.camera.target.y -= value
  if rl.IsKeyDown(rl.KeyboardKey.DOWN)  do engine.camera.target.y += value

  cap_camera(handle)
}


//
// PRIVATE
//


cap_camera :: proc(handle: ^Handle) {
  max_x := f32(handle.chunk_size.x * int(handle.displayed_tile_size)) * f32(max_chunks_per_line) - relative_to_zoom(engine.game_state.resolution.x)
  max_y := f32(handle.chunk_size.y * int(handle.displayed_tile_size)) * f32(max_chunks_per_line) - relative_to_zoom(engine.game_state.resolution.y)

  if engine.camera.target.x < 0 do engine.camera.target.x = 0
  if engine.camera.target.y < 0 do engine.camera.target.y = 0

  if engine.camera.target.x > max_x do engine.camera.target.x = max_x
  if engine.camera.target.y > max_y do engine.camera.target.y = max_y
}



// input_system_old :: proc() {
//   time := rl.GetFrameTime()
//
//   size := i32(BOX_SIZE) / 2
//   mouse_pos := to_cell_position({ rl.GetMouseX(), rl.GetMouseY() })
//   handle := &terrain.table_terrains.items[0].handle
//
//   @(static) selection_start: [2]i32
//   @(static) selecting:= false
//
//   @(static) txt := 0
//
//
//   if rl.IsMouseButtonPressed(rl.MouseButton.RIGHT) {
//     selection_start = to_cell_position({ rl.GetMouseX(), rl.GetMouseY() })
//     selecting = true
//   }
//
//   if rl.IsMouseButtonReleased(rl.MouseButton.RIGHT) {
//     selecting = false
//
//     first_point: [2]i32 = { min(selection_start.x, mouse_pos.x), min(selection_start.y, mouse_pos.y) }
//     last_point: [2]i32 = { max(selection_start.x, mouse_pos.x), max(selection_start.y, mouse_pos.y) }
//
//     chunks_to_redraw: [dynamic]^terrain.Chunk
//
//     for y in first_point.y..<last_point.y {
//       for x in first_point.x..<last_point.x {
//         chunk_x := int((x / i32(handle.chunk_size.x)) / size)
//         chunk_y := int((y / i32(handle.chunk_size.y)) / size)
//         chunk_terrain_x := int(x / size) % handle.chunk_size.x
//         chunk_terrain_y := int(y / size) % handle.chunk_size.y
//
//         chunk: ^terrain.Chunk = nil
//
//         for &c in handle.chunks {
//           if c.position.x == chunk_x && c.position.y == chunk_y {
//             chunk = &c
//
//             chunk.terrain[chunk_terrain_y][chunk_terrain_x].tileset_pos = { 0, 0 }
//             context.user_ptr = &c
//
//             _, found := slice.linear_search_proc(chunks_to_redraw[:], proc(p: ^terrain.Chunk) -> bool {
//               chunk: ^terrain.Chunk = cast(^terrain.Chunk)context.user_ptr
//
//               return p.position.x == chunk.position.x && p.position.y == chunk.position.y
//             })
//
//             if !found {
//               append(&chunks_to_redraw, &c)
//             }
//           }
//         }
//       }
//     }
//
//     rl.EndMode2D()
//     for &chunk in chunks_to_redraw {
//       terrain.draw_chunk(handle, chunk)
//     }
//     rl.BeginMode2D(engine.camera)
//   }
//
//   bbox := engine.database_get_component(0, &table_bounding_boxes[4])
//   bbox.box.x = f32(mouse_pos.x)
//   bbox.box.y = f32(mouse_pos.y)
//
//   if selecting {
//     first_point: [2]i32 = { min(selection_start.x, mouse_pos.x), min(selection_start.y, mouse_pos.y) }
//     last_point: [2]i32 = { max(selection_start.x, mouse_pos.x), max(selection_start.y, mouse_pos.y) }
//
//     ui_text_box_draw(string(rl.TextFormat("%dx%d", abs(last_point.x - first_point.x) / size, abs(last_point.y - first_point.y) / 16)), i32(18.0 * (1 / engine.camera.zoom)), bbox, 1)
//
//     rl.DrawRectangle(first_point.x, first_point.y, last_point.x - first_point.x, last_point.y - first_point.y, rl.Color { 255, 0, 0, 100 })
//   } else {
//     rl.DrawRectangle(mouse_pos.x, mouse_pos.y, size, size, rl.Color { 255, 0, 0, 100 })
//   }
// }
