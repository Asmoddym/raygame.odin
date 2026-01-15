#+feature dynamic-literals

// There can be some interesting stuff to get from https://www.youtube.com/watch?v=6BdYzfVOyBY
// I followed it on my very first try to have continents but I removed it later in favor of my base_altitude method.
//
// Could be worth checking out to have some nice oceans though.

package terrain

import "base:builtin"
import rand "core:math/rand"
import math "core:math"
import perlin_noise "../lib/perlin_noise"
import rl "vendor:raylib"

// Chunk data struct to the x and y coords.
// Holds the render_texture loaded with (handle.chunk_size * handle_tile_size) pixels for width and height.
// terrain contains handle.chunk_size.y rows, each containing handle.chunk_size.x cells
Chunk :: struct {
  render_texture: rl.RenderTexture,
  position: [2]i32,
}

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
}


// PROCS


// Terrain generator.
// Takes the number of chunks and the tileset to be used for this terrain.
// Returns a Handle pointer.
generate_terrain :: proc(size: i32, tileset: rl.Texture) -> ^Handle {
  handle: ^Handle             = new(Handle)

  handle.cell_count_per_side  = size * CHUNK_SIZE
  handle.tiles                = make([dynamic]TerrainCell, handle.cell_count_per_side * handle.cell_count_per_side)
  handle.display_chunks       = make([dynamic]Chunk, size * size)
  handle.chunks_per_side      = size
  handle.tileset              = tileset

  handle.default_noise_handle = perlin_noise.initialize_handle()
  handle.biome_noise_handle   = perlin_noise.initialize_handle()

  perlin_noise.repermutate(&handle.biome_noise_handle)
  perlin_noise.repermutate(&handle.default_noise_handle)

  for y in 0..<handle.cell_count_per_side {
    for x in 0..<handle.cell_count_per_side {
      idx := y * handle.cell_count_per_side + x

      handle.tiles[idx] = generate_terrain_cell(handle, x, y)
    }
  }

  for chunk_y in 0..<handle.chunks_per_side {
    for chunk_x in 0..<handle.chunks_per_side {
      idx := chunk_y * handle.chunks_per_side + chunk_x

      handle.display_chunks[idx] = generate_display_chunk(handle, chunk_x, chunk_y)
    }
  }

  return handle
}

// Draw / redraw a display chunk.
draw_display_chunk :: proc(handle: ^Handle, chunk: ^Chunk) {
  rl.BeginTextureMode(chunk.render_texture)
  rl.ClearBackground(rl.BLACK)

  chunk_tile_position: [2]i32 = { chunk.position.x * CHUNK_SIZE, chunk.position.y * CHUNK_SIZE }

  for y in 0..<CHUNK_SIZE {
    for x in 0..<CHUNK_SIZE {
      cell := &handle.tiles[(chunk_tile_position.y + y) * handle.cell_count_per_side + (chunk_tile_position.x + x)]

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
      rl.DrawTexturePro(handle.tileset, source, dest, { 0, 0 }, 0, rl.WHITE)
    }
  }
  rl.DrawText(rl.TextFormat("%d, %d", chunk.position.x, chunk.position.y), 0, 0, 40, rl.WHITE)
  rl.EndTextureMode()
}

// Unloads stuff generated in generate_terrain.
// FREES THE POINTER.
delete_terrain :: proc(handle: ^Handle) {
  delete(handle.tiles)

  for &chunk in handle.display_chunks {
    rl.UnloadRenderTexture(chunk.render_texture)
  }

  delete(handle.display_chunks)
  free(handle)
}



//
// PRIVATE
//



// CELLS


// Generate the terrain cell at the given x and y coords.
@(private="file")
generate_terrain_cell :: proc(handle: ^Handle, #any_int x, y: i32) -> TerrainCell {
  detail_value, base_altitude_value, altitude: f32
  altitude = 0

  biome_value := generate_biome_value(handle, x, y)
  base_altitude_value = generate_base_altitude_value(handle, x, y)
  detail_value = generate_detail_value(handle, x, y)

  altitude += 2.0 * detail_value - 1
  altitude += base_altitude_value

  return create_cell(y, x, altitude, biome_value, base_altitude_value, detail_value)
}

// Single cell creation.
// Will iterate through the biomes and apply a tileset position to the cell.
@(private="file")
create_cell :: proc(y, x: i32, altitude, biome_value, base_altitude_value, detail_value: f32) -> TerrainCell {
  tileset_pos: [2]i32 = { -1, -1 }

  altitude_overlap_interval: [2]f32 = { altitude - layer_threshold, altitude + layer_threshold }
  biome_overlap_interval: [2]f32 = { biome_value - biome_threshold, biome_value + biome_threshold }

  biome: ^BiomeDescriptor = &biome_descriptors[0]

  for idx in 0..<len(biome_descriptors) {
    current_biome := &biome_descriptors[idx]

    // Very naive approach but if kinda works for forest patches
    if biome_overlap_interval.x >= current_biome.interval.x && biome_overlap_interval.y < current_biome.interval.y {
      biome = &biome_descriptors[idx]
    }
  }

  selected_layer_idx := -1

  for current_layer_idx in 0..<len(biome.layers) {
    next_layer_idx     := current_layer_idx + 1 < len(biome.layers) ? current_layer_idx + 1 : current_layer_idx
    previous_layer_idx := current_layer_idx - 1 >= 0 ? current_layer_idx - 1 : current_layer_idx

    current_layer      := &biome.layers[current_layer_idx]
    previous_layer     := &biome.layers[previous_layer_idx]
    next_layer         := &biome.layers[next_layer_idx]

    if altitude_overlap_interval.x >= current_layer.interval.x && altitude_overlap_interval.y < current_layer.interval.y {
      selected_layer_idx = current_layer_idx
    }

    overall_descriptor_overlap: [2]f32 = { previous_layer.interval.y - layer_threshold, next_layer.interval.x + layer_threshold }

    if altitude >= overall_descriptor_overlap.x && altitude <= overall_descriptor_overlap.y {
      distance := 100 - math.remap_clamped(altitude, overall_descriptor_overlap.x, overall_descriptor_overlap.y, 0, 100)
      chances := i32(rand.int31()) % 100

      if chances >= 10 {
        selected_layer_idx = current_layer_idx
        break
      }

      if distance < 15 {
        selected_layer_idx = next_layer_idx
      } else if distance >= 15 && distance < 85 {
        selected_layer_idx = current_layer_idx
      } else {
        selected_layer_idx = previous_layer_idx
      }

      break
    }
  }

   tileset_pos = biome.layers[selected_layer_idx].tileset_position

  return TerrainCell {
    altitude,
    biome_value,
    base_altitude_value,
    detail_value,
    tileset_pos,
    { x, y },
  }
}

// Base altitude generation using default_noise_handle.
// Values are exagerated to force some altitude changes.
@(private="file")
generate_base_altitude_value :: proc(handle: ^Handle, x, y: i32) -> f32 {
  base_altitude_value := perlin_noise.octave_perlin(&handle.default_noise_handle, x, y, noise_scale = 0.004, persistence = 0.4)

  return math.remap_clamped(base_altitude_value, 0, 1, -2, 2) + 0.1
}

// Detail value generation using default_noise_handle.
@(private="file")
generate_detail_value :: proc(handle: ^Handle, x, y: i32) -> f32 {
  return perlin_noise.octave_perlin(&handle.default_noise_handle, x, y, noise_scale = 0.015, persistence = 0.5)
}

// Biome value generation using biome_noise_handle.
// Not very detailed and used for some additional details such as forest patches.
@(private="file")
generate_biome_value :: proc(handle: ^Handle, x, y: i32) -> f32 {
  return perlin_noise.octave_perlin(&handle.biome_noise_handle, x, y, noise_scale = 0.015, persistence = 0.3)
}


// DISPLAY CHUNKS

// Generate a display chunk from the chunk coords.
@(private="file")
generate_display_chunk :: proc(handle: ^Handle, chunk_x, chunk_y: i32) -> Chunk {
  chunk := Chunk {
    rl.LoadRenderTexture(CHUNK_PIXEL_SIZE, CHUNK_PIXEL_SIZE),
    { chunk_x, chunk_y },
  }

  draw_display_chunk(handle, &chunk)

  return chunk
}


// TYPEDEFS


// All available terrain cell types.
@(private="file")
TerrainCellType :: enum {
  OCEAN,
  SAND,
  GRASS_1,
  GRASS_2,
  GRASS_3,
  HILL_1,
  HILL_2,
  DARK_DRASS_1,
  FOREST,
  DARK_FOREST,
  SNOWY_FOREST,
  MOUNTAINS_1,
  SNOW,
  SNOWY_MOUNTAINS,
  VOLCANO,
  TYPES,
}

// All available biome types.
@(private="file")
BiomeType :: enum {
  PLAINS,
  FOREST,
  BIOMES,
}

// Internal descriptor for biome layers
@(private="file")
LayerDescriptor :: struct {
  type: TerrainCellType,
  interval: [2]f32,
  tileset_position: [2]i32,
}

// Internal descriptor for biomes
@(private="file")
BiomeDescriptor :: struct {
  type: BiomeType,
  interval: [2]f32,
  layers: [dynamic]LayerDescriptor,
}


// CONSTANTS


// Biome descriptors; will change.
@(private="file")
biome_descriptors: [BiomeType.BIOMES]BiomeDescriptor = {
  {
    .PLAINS,
    { 0, 0.65 },
    {
      { .OCEAN, { -10, -0.3 }, { 26, 10 } },
      { .SAND, { -0.3, -0.2 }, { 20, 2 } },
      { .GRASS_1, { -0.2, -0.1 }, { 5, 0 } },
      { .GRASS_2, { -0.1, 0 }, { 13, 0 } },
      { .HILL_1, { 0, 0.1 }, { 10, 0 } },
      { .HILL_2, { 0.1, 0.25 }, { 20, 0 } },
      { .DARK_DRASS_1, { 0.25, 0.35 }, { 4, 6 } },
      { .FOREST, { 0.35, 0.45 }, { 2, 16 } },
      { .DARK_FOREST, { 0.45, 0.5 }, { 21, 16 } },
      { .MOUNTAINS_1, { 0.5, 0.7 }, { 15, 3 } },
      { .SNOW, { 0.7, 0.8 }, { 20, 3 } },
      { .SNOWY_FOREST, { 0.8, 0.9 }, { 12, 17 } },
      { .SNOWY_MOUNTAINS, { 0.9, 1.1 }, { 28, 3 } },
      { .VOLCANO, { 1.1, 2 }, { 21, 9 } },
    },
  },
  {
    .FOREST,
    { 0.65, 10 },
    {
      { .OCEAN, { -10, -0.3 }, { 26, 10 } },
      { .SAND, { -0.3, -0.2 }, { 20, 2 } },
      { .GRASS_1, { -0.2, -0.1 }, { 5, 0 } },
      { .FOREST, { -0.1, 0 },       { 21, 16 } },
      { .FOREST, { 0, 0.1 },        { 2, 16 } },
      { .DARK_FOREST, { 0.1, 0.2 }, { 21, 16 } },
      { .FOREST, { 0.2, 0.3 },      { 2, 16 } },
      { .DARK_FOREST, { 0.3, 0.4 }, { 21, 16 } },
      { .FOREST, { 0.4, 0.5 },      { 2, 16 } },
      { .DARK_FOREST, { 0.5, 0.6 }, { 21, 16 } },
      { .FOREST, { 0.6, 0.7 },      { 2, 16 } },
      { .DARK_FOREST, { 0.7, 0.8 }, { 21, 16 } },
      { .SNOWY_FOREST, { 0.8, 10 }, { 12, 17 } },
    },
  },
}

// Interval layer_threshold between biome layers.
// Used to calculate the "width" of the shared border.
@(private="file")
layer_threshold: f32 = 0.01

// Interval layer_threshold between biomes.
// Used to calculate the "width" of the shared border.
@(private="file")
biome_threshold: f32 = 0.02
