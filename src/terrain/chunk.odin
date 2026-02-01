package terrain

import rl "vendor:raylib"


// PROCS


// Generate a display chunk from the chunk coords.
generate_display_chunk :: proc(chunk_x, chunk_y: i32) -> Chunk {
  chunk := Chunk {
    rl.LoadRenderTexture(CHUNK_PIXEL_SIZE, CHUNK_PIXEL_SIZE),
    rl.LoadRenderTexture(CHUNK_PIXEL_SIZE, CHUNK_PIXEL_SIZE),
    { chunk_x, chunk_y },
  }

  draw_display_chunk(&chunk)

  rl.BeginTextureMode(chunk.mask)
  rl.ClearBackground(rl.BLACK)
  rl.EndTextureMode()

  return chunk
}

// Draw / redraw a display chunk.
draw_display_chunk :: proc(chunk: ^Chunk) {
  rl.BeginTextureMode(chunk.render_texture)
  rl.ClearBackground(rl.BLACK)

  chunk_tile_position: [2]i32 = { chunk.position.x * CHUNK_SIZE, chunk.position.y * CHUNK_SIZE }

  for y in 0..<CHUNK_SIZE {
    for x in 0..<CHUNK_SIZE {
      cell_idx := coords_to_tile_index({ chunk_tile_position.x + x, chunk_tile_position.y + y })
      cell := &_handle.tiles[cell_idx]

      source := rl.Rectangle {
        f32(cell.tileset_pos.x) * F32_TILE_SIZE,
        f32(cell.tileset_pos.y) * F32_TILE_SIZE,
        F32_TILE_SIZE,
        F32_TILE_SIZE,
      }

      dest := rl.Rectangle {
        f32(x) * F32_TILE_SIZE,
        f32(y) * F32_TILE_SIZE,
        F32_TILE_SIZE,
        F32_TILE_SIZE,
      }

      rl.DrawTexturePro(_handle.tileset, source, dest, { 0, 0 }, 0, rl.WHITE)
    }
  }

  rl.DrawText(rl.TextFormat("%d, %d", chunk.position.x, chunk.position.y), 0, 0, 40, rl.WHITE)
  rl.EndTextureMode()
}

// Draw / redraw a display chunk.
draw_mask_chunk :: proc(chunk: ^Chunk) {
  rl.BeginTextureMode(chunk.mask)
  rl.ClearBackground(rl.BLACK)

  chunk_tile_position: [2]i32 = { chunk.position.x * CHUNK_SIZE, chunk.position.y * CHUNK_SIZE }

  for y in 0..<CHUNK_SIZE {
    for x in 0..<CHUNK_SIZE {
      cell_idx := coords_to_tile_index({ chunk_tile_position.x + x, chunk_tile_position.y + y })
      cell := &_handle.tiles[cell_idx]

      rl.DrawRectangle(
        x * TILE_SIZE,
        y * TILE_SIZE,
        TILE_SIZE,
        TILE_SIZE,
        cell.discovered ? rl.GRAY : rl.BLACK,
      )
    }
  }
  rl.EndTextureMode()
}

