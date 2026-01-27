package terrain

import "core:log"
import "../engine"
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
      cell := &_handle.tiles[(chunk_tile_position.y + y) * _handle.cell_count_per_side + (chunk_tile_position.x + x)]

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

  coords := to_cell_coords(rl.GetScreenToWorld2D(rl.GetMousePosition(), engine.camera))

  for y in 0..<CHUNK_SIZE {
    for x in 0..<CHUNK_SIZE {
      cell := &_handle.tiles[(chunk_tile_position.y + y) * _handle.cell_count_per_side + (chunk_tile_position.x + x)]

      rl.DrawRectangle(
        x * TILE_SIZE,
        y * TILE_SIZE,
        TILE_SIZE,
        TILE_SIZE,
        cell.discovered ? (rl.CheckCollisionPointRec({ f32(coords.x), f32(coords.y) }, rl.Rectangle { f32(cell.position.x - 3), f32(cell.position.y - 3), 7, 7 }) ? rl.WHITE : rl.GRAY) : rl.BLACK,
      )
    }
  }
  rl.EndTextureMode()
}

