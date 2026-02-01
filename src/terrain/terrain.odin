package terrain

// There can be some interesting stuff to get from https://www.youtube.com/watch?v=6BdYzfVOyBY
// I followed it on my very first try to have continents but I removed it later in favor of my base_altitude method.
//
// Could be worth checking out to have some nice oceans though.

import math "core:math"
import perlin_noise "../lib/perlin_noise"
import engine "../engine"
import rl "vendor:raylib"


// Terrain handle to store specific configuration.
// All generated chunks are stored in the chunks slice.
Handle :: struct {
  tileset: rl.Texture,

  tiles: [dynamic]TerrainCell,
  display_chunks: [dynamic]Chunk,

  chunks_per_side: i32,
  cell_count_per_side: i32,

  default_noise_handle: perlin_noise.Handle,
  biome_noise_handle: perlin_noise.Handle,
}

// Terrain cell data (display-only for now) struct.
// tileset_pos holds the x,y position in the tileset (X first).
TerrainCell :: struct {
  altitude: f32,
  biome_value: f32,
  base_altitude_value: f32,
  detail_value: f32,
  tileset_pos: [2]i32,
  position: [2]i32,

  discovered: bool,
}

// Chunk data struct to the x and y coords.
// Holds the render_texture loaded with (handle.chunk_size * handle_tile_size) pixels for width and height.
// terrain contains handle.chunk_size.y rows, each containing handle.chunk_size.x cells
Chunk :: struct {
  render_texture: rl.RenderTexture,
  mask: rl.RenderTexture,
  position: [2]i32,
}


// SYSTEMS


// Main draw system.
draw :: proc() {
  draw_visible_map(&engine.camera)
  draw_hover()
}


// PROCS


// Generate a terrain.
// Takes the number of chunks and the tileset to be used for this terrain.
// Returns a Handle pointer.
generate :: proc(size: i32) {
  _handle.cell_count_per_side  = size * CHUNK_SIZE
  _handle.tiles                = make([dynamic]TerrainCell, _handle.cell_count_per_side * _handle.cell_count_per_side)
  _handle.display_chunks       = make([dynamic]Chunk, size * size)
  _handle.chunks_per_side      = size
  _handle.tileset              = engine.assets_find_or_create(rl.Texture2D, TILESET_PATH)

  _handle.default_noise_handle = perlin_noise.initialize_handle()
  _handle.biome_noise_handle   = perlin_noise.initialize_handle()

  perlin_noise.repermutate(&_handle.biome_noise_handle)
  perlin_noise.repermutate(&_handle.default_noise_handle)

  for y in 0..<_handle.cell_count_per_side {
    for x in 0..<_handle.cell_count_per_side {
      idx := y * _handle.cell_count_per_side + x

      _handle.tiles[idx] = generate_cell(x, y)
    }
  }

  for chunk_y in 0..<_handle.chunks_per_side {
    for chunk_x in 0..<_handle.chunks_per_side {
      idx := chunk_y * _handle.chunks_per_side + chunk_x

      _handle.display_chunks[idx] = generate_display_chunk(chunk_x, chunk_y)
    }
  }
}

// Unloads stuff generated in generate_terrain.
// FREES THE POINTER.
unload :: proc() {
  delete(_handle.tiles)

  for &chunk in _handle.display_chunks {
    rl.UnloadRenderTexture(chunk.render_texture)
  }

  delete(_handle.display_chunks)
}

// Draw only the chunks of the map that are in the viewing range.
draw_visible_map :: proc(camera: ^rl.Camera2D) {
  drawn_rec := [2]rl.Vector2 {
    rl.GetScreenToWorld2D({ 0, 0 }, camera^),
    rl.GetScreenToWorld2D({ f32(engine.game_state.resolution.x), f32(engine.game_state.resolution.y) }, camera^),
  }

  drawn_rec[0] = { math.ceil(drawn_rec[0].x), math.round(drawn_rec[0].y) }
  drawn_rec[1] = { math.ceil(drawn_rec[1].x), math.round(drawn_rec[1].y) }

  for &c in _handle.display_chunks {
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

    draw_chunk(&c, pos)
  }

  // Mask
  rl.BeginBlendMode(rl.BlendMode.MULTIPLIED)
  for &c in _handle.display_chunks {
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

    draw_mask(&c, pos)
  }
  rl.EndBlendMode()
}

// Draw all the map regardless of the camera. Shouldn't be used to draw the main map as we don't need out-of-range chunks
draw_whole_map:: proc() {
  for &c in _handle.display_chunks {
    pos: [2]f32 = {
      f32(c.position.x * CHUNK_PIXEL_SIZE),
      f32(c.position.y * CHUNK_PIXEL_SIZE),
    }

    draw_chunk(&c, pos)
  }

  // Mask
  rl.BeginBlendMode(rl.BlendMode.MULTIPLIED)
  for &c in _handle.display_chunks {
    pos: [2]f32 = {
      f32(c.position.x * CHUNK_PIXEL_SIZE),
      f32(c.position.y * CHUNK_PIXEL_SIZE),
    }

    draw_mask(&c, pos)
  }
  rl.EndBlendMode()
}



// PRIVATE



// Temporary. Draws the current hovered cell with a 3 block offset.
@(private="file")
draw_hover :: proc() {
  point := get_current_hovered_cell_coords()

  rl.DrawRectangle(
    point.x * TILE_SIZE,
    point.y * TILE_SIZE,
    TILE_SIZE,
    TILE_SIZE,
    rl.Color { 255, 0, 0, 255 },
  )
}

// Draw a chunk with its mask.
@(private="file")
draw_chunk :: proc(c: ^Chunk, pos: [2]f32) {
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

draw_mask :: proc(c: ^Chunk, pos: [2]f32) {
  rl.DrawTextureRec(
    c.mask.texture,
    rl.Rectangle { 0, 0,
      F32_CHUNK_PIXEL_SIZE,
      -F32_CHUNK_PIXEL_SIZE,
    },
    rl.Vector2 { pos.x, pos.y },
    rl.Color { 255, 255, 255, 255 },
  )
}



// GLOBALS



_handle: Handle
