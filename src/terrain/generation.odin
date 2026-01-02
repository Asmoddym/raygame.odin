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
  terrain: [dynamic][dynamic]TerrainCell,
  position: [2]i32,
}

// Terrain handle to store specific configuration.
// All generated chunks are stored in the chunks slice.
Handle :: struct {
  chunk_size: [2]i32,
  chunks: [dynamic]Chunk,
  tileset: rl.Texture,
  tile_size: i32,
  displayed_tile_size: i32,
  chunk_pixel_size: [2]i32,

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


// Handle initializer.
// Takes the chunk dimensions and the tileset to be used for this terrain as well as the continent dimensions (check Handle definition for more info)
initialize_handle :: proc(#any_int chunk_width, chunk_height: i32, tileset: rl.Texture, tile_size: i32 = 16, displayed_tile_size: i32 = 16) -> Handle {
  return Handle {
    { chunk_width, chunk_height },
    {},
    tileset,
    tile_size,
    displayed_tile_size,
    {
      chunk_width * displayed_tile_size,
      chunk_height * displayed_tile_size,
    },
    perlin_noise.initialize_handle(),
    perlin_noise.initialize_handle(),
  }
}

// Generate the chunk at the given x and y coords.
generate_chunk :: proc(handle: ^Handle, #any_int x, y: i32) {
  append(&handle.chunks, Chunk {
    rl.LoadRenderTexture(handle.chunk_size.x * handle.displayed_tile_size, handle.chunk_size.y * handle.displayed_tile_size),
    generate_chunk_terrain(handle, x, y),
    { x, y },
  })

  last_chunk := &handle.chunks[len(handle.chunks) - 1]

  draw_chunk(handle, last_chunk)
}

// Draw a generated chunk.
// tile_size is inversed in the source definition to display it in the right order.
draw_chunk :: proc(handle: ^Handle, chunk: ^Chunk) {
  rl.BeginTextureMode(chunk.render_texture)
  rl.ClearBackground(rl.BLACK)

  for &line in chunk.terrain {
    for &cell in line {
      source := rl.Rectangle {
        f32(cell.tileset_pos.x) * f32(handle.tile_size),
        f32(cell.tileset_pos.y) * f32(handle.tile_size),
        f32(handle.tile_size),
        f32(handle.tile_size),
      }

      dest := rl.Rectangle {
        f32(cell.position.x * handle.displayed_tile_size),
        f32(cell.position.y * handle.displayed_tile_size),
        f32(handle.displayed_tile_size),
        f32(handle.displayed_tile_size),
      }

      rl.DrawTexturePro(handle.tileset, source, dest, { 0, 0 }, 0, rl.WHITE)
    }
  }

  rl.DrawText(rl.TextFormat("%d, %d", chunk.position.x, chunk.position.y), 0, 0, 40, rl.WHITE)
  rl.EndTextureMode()
}


//
// PRIVATE
//



// PROCS


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

// Terrain generation for a given chunk x and y.
// Takes the handle too to be able to calculate the distance from the continent
@(private="file")
generate_chunk_terrain :: proc(handle: ^Handle, chunk_x, chunk_y: i32) -> [dynamic][dynamic]TerrainCell {
  terrain := make([dynamic][dynamic]TerrainCell, handle.chunk_size.y)

  for y in 0..<handle.chunk_size.y {
    relative_x, relative_y: i32

    terrain[y] = make([dynamic]TerrainCell, handle.chunk_size.x)

    for x in 0..<handle.chunk_size.x {
      detail_value, base_altitude_value, altitude: f32
      altitude = 0

      relative_y = y + handle.chunk_size.y * chunk_y
      relative_x = x + handle.chunk_size.x * chunk_x

      biome_value := generate_biome_value(handle, relative_x, relative_y)
      base_altitude_value = generate_base_altitude_value(handle, relative_x, relative_y)
      detail_value = generate_detail_value(handle, relative_x, relative_y)

      altitude += 2.0 * detail_value - 1
      altitude += base_altitude_value

      terrain[y][x] = create_cell(y, x, altitude, biome_value, base_altitude_value, detail_value)
    }
  }

  return terrain
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

  for idx in 0..<len(biome.layers) {
    current_layer := &biome.layers[idx]
    previous_layer := idx - 1 >= 0 ? &biome.layers[idx - 1] : current_layer
    next_layer := idx + 1 < len(biome.layers) ? &biome.layers[idx + 1] : current_layer

    if altitude_overlap_interval.x >= current_layer.interval.x && altitude_overlap_interval.y < current_layer.interval.y {
      tileset_pos = current_layer.tileset_position
    }

    overall_descriptor_overlap: [2]f32 = { previous_layer.interval.y - layer_threshold, next_layer.interval.x + layer_threshold }

    if altitude >= overall_descriptor_overlap.x && altitude <= overall_descriptor_overlap.y {
      distance := 100 - math.remap_clamped(altitude, overall_descriptor_overlap.x, overall_descriptor_overlap.y, 0, 100)
      chances := i32(rand.int31()) % 100

      if chances >= 10 {
        tileset_pos = current_layer.tileset_position
        break
      }

      if distance < 15 {
        tileset_pos = next_layer.tileset_position
      } else if distance >= 15 && distance < 85 {
        tileset_pos = current_layer.tileset_position
      } else {
        tileset_pos = previous_layer.tileset_position
      }

      break
    }
  }

  return TerrainCell {
    altitude,
    biome_value,
    base_altitude_value,
    detail_value,
    tileset_pos,
    { x, y },
  }
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
