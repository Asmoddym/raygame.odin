#+feature dynamic-literals
package terrain

import "core:fmt"
import "core:relative"
import "base:builtin"
import rand "core:math/rand"
import math "core:math"
import perlin_noise "../lib/perlin_noise"
import rl "vendor:raylib"

debug_draw_mode := 0

// Chunk data struct to the x and y coords.
// Holds the render_texture loaded with (handle.chunk_size * handle_tile_size) pixels for width and height.
// terrain contains handle.chunk_size.y rows, each containing handle.chunk_size.x cells
Chunk :: struct {
  render_texture: rl.RenderTexture,
  terrain: [dynamic][dynamic]TerrainCell,
  position: [2]int,
}

// Terrain handle to store specific configuration.
// All generated chunks are stored in the chunks slice.
Handle :: struct {
  chunk_size: [2]int,
  chunks: [dynamic]Chunk,
  tileset: rl.Texture,
  tile_size: i32,
  displayed_tile_size: i32,

  default_noise_handle: perlin_noise.Handle,
  biome_noise_handle: perlin_noise.Handle,
}


// PROCS


// Handle initializer.
// Takes the chunk dimensions and the tileset to be used for this terrain as well as the continent dimensions (check Handle definition for more info)
initialize_handle :: proc(#any_int chunk_width, chunk_height: int, tileset: rl.Texture, tile_size: i32 = 16, displayed_tile_size: i32 = 16) -> Handle {
  return Handle {
    { chunk_width, chunk_height },
    {},
    tileset,
    tile_size,
    displayed_tile_size,
    perlin_noise.initialize_handle(),
    perlin_noise.initialize_handle(),
  }
}

// Generate the chunk at the given x and y coords.
generate_chunk :: proc(handle: ^Handle, #any_int x, y: int) {
  append(&handle.chunks, Chunk {
    rl.LoadRenderTexture(i32(handle.chunk_size.x) * handle.displayed_tile_size, i32(handle.chunk_size.y) * handle.displayed_tile_size),
    generate_chunk_terrain(handle, x, y),
    { x, y },
  })

  last_chunk := &handle.chunks[len(handle.chunks) - 1]

  draw_chunk(handle, last_chunk)
}



//
// PRIVATE
//



// PROCS


generate_base_altitude_value :: proc(handle: ^perlin_noise.Handle, x, y: int) -> f32 {
  base_altitude_value := perlin_noise.octave_perlin(handle, x, y, noise_scale = 0.0015, persistence = 0.4)

  return math.remap_clamped(base_altitude_value, 0, 1, -2.3, 2)
}

generate_detail_value :: proc(handle: ^perlin_noise.Handle, x, y: int) -> f32 {
  return perlin_noise.octave_perlin(handle, x, y, noise_scale = 0.015, persistence = 0.5)
}

// Terrain generation for a given chunk x and y.
// Takes the handle too to be able to calculate the distance from the continent
@(private="file")
generate_chunk_terrain :: proc(handle: ^Handle, chunk_x, chunk_y: int) -> [dynamic][dynamic]TerrainCell {
  terrain := make([dynamic][dynamic]TerrainCell, handle.chunk_size.y)

  for y in 0..<handle.chunk_size.y {
    relative_x, relative_y: int

    terrain[y] = make([dynamic]TerrainCell, handle.chunk_size.x)

    for x in 0..<handle.chunk_size.x {
      detail_value, base_altitude_value, altitude: f32
      altitude = 0

      relative_y = y + handle.chunk_size.y * chunk_y
      relative_x = x + handle.chunk_size.x * chunk_x

      biome_value := perlin_noise.octave_perlin(&handle.biome_noise_handle, relative_x, relative_y, noise_scale = 0.01, persistence = 0.4)
      // biome_value := perlin_noise.perlin(&handle.biome_noise_handle, relative_x, relative_y, noise_scale = 0.05)

      if debug_draw_mode == 0 {
        base_altitude_value = generate_base_altitude_value(&handle.default_noise_handle, relative_x, relative_y)
        detail_value = generate_detail_value(&handle.default_noise_handle, relative_x, relative_y)

        altitude += 2.0 * detail_value - 1
        altitude += base_altitude_value
      }

      // altitude += 2.0 * biome_value - 1

      terrain[y][x] = create_cell(y, x, altitude, biome_value)
    }
  }

  return terrain
}

// Draw a generated chunk.
// tile_size is inversed in the source definition to display it in the right order.
@(private="file")
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
        f32(i32(cell.position.x) * handle.displayed_tile_size),
        f32(i32(cell.position.y) * handle.displayed_tile_size),
        f32(handle.displayed_tile_size),
        f32(handle.displayed_tile_size),
      }

      rl.DrawTexturePro(handle.tileset, source, dest, { 0, 0 }, 0, rl.WHITE)
    }
  }

  rl.DrawText(rl.TextFormat("%d, %d", chunk.position.x, chunk.position.y), 0, 0, 40, rl.WHITE)
  rl.EndTextureMode()
}

// Single cell creation.
// Will iterate through the biome descriptors and apply a tileset position to the cell.
@(private="file")
create_cell :: proc(y, x: int, altitude, biome_value: f32) -> TerrainCell {
  tileset_pos: [2]int= { -1, -1 }

  altitude_overlap_interval: [2]f32 = { altitude - layer_threshold, altitude + layer_threshold }
  biome_overlap_interval: [2]f32 = { biome_value - biome_threshold, biome_value + biome_threshold }

  biome: ^BiomeDescriptor = &biome_descriptors[0]

  for idx in 0..<len(biome_descriptors) {
    current_biome := &biome_descriptors[idx]
    previous_biome := idx - 1 >= 0 ? &biome_descriptors[idx - 1] : current_biome
    next_biome := idx + 1 < len(biome_descriptors) ? &biome_descriptors[idx + 1] : current_biome

    if biome_overlap_interval.x >= current_biome.interval.x && biome_overlap_interval.y < current_biome.interval.y {
      biome = &biome_descriptors[idx]
    }

    overall_descriptor_overlap: [2]f32 = { previous_biome.interval.y - biome_threshold, next_biome.interval.x + biome_threshold }

    if altitude >= overall_descriptor_overlap.x && altitude <= overall_descriptor_overlap.y {
      distance := 100 - math.remap_clamped(altitude, overall_descriptor_overlap.x, overall_descriptor_overlap.y, 0, 100)
      chances := int(rand.int31()) % 100

      if chances >= 20 {
        biome = current_biome
        break
      }

      if distance < 15 {
        biome = next_biome
      } else if distance >= 15 && distance < 85 {
        biome = current_biome
      } else {
        biome = previous_biome
      }

      break
    }


    // descriptor_overlap := [2]f32 { biome_descriptors[idx - 1].interval.y - biome_threshold, descriptor.interval.x + biome_threshold }
    //
    // if biome_value >= descriptor_overlap.x && biome_value <= descriptor_overlap.y {
    //   distance         := 100 - math.remap_clamped(biome_value, descriptor_overlap.x, descriptor_overlap.y, 0, 100)
    //   other_desc_id    := idx + (distance < 50.0 ? 0 : -1)
    //   other_descriptor := &biome_descriptors[other_desc_id]
    //   chances          := int(rand.int31()) % 100
    //
    //   biome = chances <= int(distance /2 ) ? other_descriptor : descriptor
    //   break
    // }
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
      chances := int(rand.int31()) % 100

      if chances >= 20 {
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

// Internal descriptor for "biomes"
@(private="file")
LayerDescriptor :: struct {
  type: TerrainCellType,
  interval: [2]f32,
  tileset_position: [2]int,
}

BiomeType :: enum {
  PLAINS,
  TOUNDRA,
  FOREST,
  BIOMES,
}

BiomeDescriptor :: struct {
  type: BiomeType,
  interval: [2]f32,
  layers: [dynamic]LayerDescriptor,
}

// Terrain cell data (display-only for now) struct.
// tileset_pos holds the x,y position in the tileset (X first).
@(private="file")
TerrainCell :: struct {
  altitude: f32,
  tileset_pos: [2]int,
  position: [2]int,
}


// CONSTANTS


// This is done to compensate the fact that the rectangle window would make the main continent "oval"
// Actually, we'll voluntarily give it an oval shape
@(private="file")
y_scaling_coef: f32 = 1.5

// Biome descriptors; will change.
@(private="file")
biome_descriptors: [BiomeType.BIOMES]BiomeDescriptor = {
  {
    .PLAINS,
    { 0, 0.5 },
    {
      { .OCEAN, { -10, -0.3 }, { 26, 10 } },
      { .SAND, { -0.3, -0.2 }, { 20, 2 } },
      { .GRASS_1, { -0.2, -0.1 }, { 5, 0 } },
      { .GRASS_2, { -0.1, 0 }, { 13, 0 } },
      { .HILL_1, { 0, 0.1 }, { 10, 0 } },
      { .HILL_2, { 0.1, 10 }, { 20, 0 } },
      // { .OCEAN, { -10, -0.3 }, { 26, 10 } },
      // { .SAND, { -0.3, -0.2 }, { 20, 2 } },
      // { .GRASS_1, { -0.2, -0.1 }, { 5, 0 } },
      // { .GRASS_2, { -0.1, 0 }, { 13, 0 } },
      // { .HILL_1, { 0, 0.1 }, { 10, 0 } },
      // { .HILL_2, { 0.1, 0.25 }, { 20, 0 } },
      // { .DARK_DRASS_1, { 0.25, 0.35 }, { 4, 6 } },
      // { .FOREST, { 0.35, 0.45 }, { 2, 16 } },
      // { .DARK_FOREST, { 0.45, 0.5 }, { 21, 16 } },
      // { .MOUNTAINS_1, { 0.5, 0.7 }, { 15, 3 } },
      // { .SNOW, { 0.7, 0.8 }, { 20, 3 } },
      // { .SNOWY_FOREST, { 0.8, 0.9 }, { 12, 17 } },
      // { .SNOWY_MOUNTAINS, { 0.9, 1.1 }, { 28, 3 } },
      // { .VOLCANO, { 1.1, 2 }, { 21, 9 } },
    },
  },
  {
    .FOREST,
    { 0.5, 0.6 },
    {
      { .OCEAN, { -10, -0.3 }, { 26, 10 } },
      { .SAND, { -0.3, -0.2 }, { 20, 2 } },
      { .FOREST, { -0.2, 0.5 }, { 2, 16 } },
      { .DARK_FOREST, { 0.5, 10 }, { 21, 16 } },
    },
  },
  {
    .TOUNDRA,
    { 0.6, 9 },
    {
      { .OCEAN, { -10, -0.3 }, { 26, 10 } },
      { .SAND, { -0.3, -0.2 }, { 20, 2 } },
      { .SNOWY_FOREST, { -0.2, 0.5 }, { 12, 17 } },
      { .SNOWY_MOUNTAINS, { 0.5, 10 }, { 28, 3 } },
    },
  },
}

// Interval layer_threshold between biome layers.
// Used to calculate the "width" of the shared border.
@(private="file")
layer_threshold: f32 = 0.005

// Interval layer_threshold between biomes.
// Used to calculate the "width" of the shared border.
@(private="file")
biome_threshold: f32 = 0.02
