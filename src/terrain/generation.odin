package terrain

import "core:fmt"
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
  position: [2]int,
}

// Terrain handle to store specific configuration.
// All generated chunks are stored in the chunks slice.
//
// continent_dimensions stores the "land" dimensions. When the algorithm starts to go past these values, water will be generated.
Handle :: struct {
  chunk_size: [2]int,
  chunks: [dynamic]Chunk,
  tileset: rl.Texture,
  tile_size: i32,
  displayed_tile_size: i32,
  continent_dimensions: [2]int,
}


// PROCS


// Handle initializer.
// Takes the chunk dimensions and the tileset to be used for this terrain as well as the continent dimensions (check Handle definition for more info)
initialize_handle :: proc(#any_int chunk_width, chunk_height: int, tileset: rl.Texture, continent_dimensions: [2]int, tile_size: i32 = 16, displayed_tile_size: i32 = 16) -> Handle {
  return Handle {
    { chunk_width, chunk_height },
    {},
    tileset,
    tile_size,
    displayed_tile_size,
    continent_dimensions,
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


// Terrain generation for a given chunk x and y.
// Takes the handle too to be able to calculate the distance from the continent
@(private="file")
generate_chunk_terrain :: proc(handle: ^Handle, chunk_x, chunk_y: int) -> [dynamic][dynamic]TerrainCell {
  terrain: [dynamic][dynamic]TerrainCell
  distance_to_center, max_distance, dx, dy: f32

  continent_width  := f32(handle.continent_dimensions.x)
  continent_height := f32(handle.continent_dimensions.y)
  terrain           = make([dynamic][dynamic]TerrainCell, handle.chunk_size.y)

  // 0.25 is for 0.5 * 0.5
  max_distance = math.sqrt(continent_width * continent_width * 0.25 + continent_height * continent_height * 0.25) //+ continent_width / 1.9

  for y in 0..<handle.chunk_size.y {
    relative_x, relative_y: int

    terrain[y] = make([dynamic]TerrainCell, handle.chunk_size.x)

    for x in 0..<handle.chunk_size.x {
      noise_value, altitude: f32
      altitude = 0

      relative_y = y + handle.chunk_size.y * chunk_y
      relative_x = x + handle.chunk_size.x * chunk_x

      // Distance from the center minus pos
      // dx = f32(continent_width * 1.5 * 0.5 - f32(relative_x))
      // dy = f32(continent_height * 1.5 * 0.5 - f32(relative_y))
      // distance_to_center =  math.sqrt(dx * dx + dy * dy * y_scaling_coef)

      // Pretty much random calculations, but it looks rather nice
      // altitude = 0.65 - 2 * (2/26.0 * distance_to_center) / max_distance
      // altitude -= 0.4 * (distance_to_center / max_distance)

      // altitude = 0.75 - 2 * (distance_to_center) / max_distance

      biome_value := perlin_noise.octave_perlin(relative_x, relative_y, noise_scale = 0.0015, persistence = 0.4)
      biome_value = math.remap_clamped(biome_value, 0, 1, -2.5, 2)

      noise_value = perlin_noise.octave_perlin(relative_x, relative_y, noise_scale = 0.015, persistence = 0.5)
      altitude += 2.0 * noise_value - 1
      altitude += biome_value

      terrain[y][x] = create_cell(y, x, altitude)
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
create_cell :: proc(y, x: int, altitude: f32) -> TerrainCell {
  tileset_pos: [2]int= { -1, -1 }

  overlap_interval: [2]f32 = { altitude - threshold, altitude + threshold }

  for idx in 0..<int(TerrainCellType.TYPES) {
    descriptor := biome_descriptors[idx]

    if overlap_interval.x >= descriptor.interval.x && overlap_interval.y < descriptor.interval.y {
      tileset_pos = descriptor.tileset_position
    }

    if idx == 0 do continue

    descriptor_overlap := [2]f32 { biome_descriptors[idx - 1].interval.y - threshold, descriptor.interval.x + threshold }

    if altitude >= descriptor_overlap.x && altitude <= descriptor_overlap.y {
      distance         := 100 - math.remap_clamped(altitude, descriptor_overlap.x, descriptor_overlap.y, 0, 100)
      other_desc_id    := idx + (distance < 50.0 ? 0 : -1)
      other_descriptor := biome_descriptors[other_desc_id]
      chances          := int(rand.int31()) % 100

      tileset_pos = chances <= int(distance * 6/5) ? other_descriptor.tileset_position : descriptor.tileset_position
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
  RIVER,
  DARK_DRASS_1,
  FOREST,
  DARK_FOREST,
  SNOWY_FOREST,
  MOUNTAINS_1,
  SNOWY_MOUNTAINS,
  VOLCANO,
  TYPES,
}

// Internal descriptor for "biomes"
@(private="file")
BiomeDescriptor :: struct {
  type: TerrainCellType,
  interval: [2]f32,
  tileset_position: [2]int,
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
biome_descriptors: [TerrainCellType.TYPES]BiomeDescriptor = {
  { .OCEAN, { -10, -0.3 }, { 26, 10 } },
  { .SAND, { -0.3, -0.2 }, { 20, 2 } },
  { .GRASS_1, { -0.2, -0.1 }, { 5, 0 } },
  { .GRASS_2, { -0.1, 0 }, { 13, 0 } },
  { .HILL_1, { 0, 0.1 }, { 10, 0 } },
  { .HILL_2, { 0.1, 0.2 }, { 20, 0 } },
  { .RIVER, { 0.2, 0.25 }, { 27, 10 } },
  { .DARK_DRASS_1, { 0.25, 0.35 }, { 4, 6 } },
  { .FOREST, { 0.35, 0.45 }, { 2, 16 } },
  { .DARK_FOREST, { 0.45, 0.5 }, { 21, 16 } },
  { .MOUNTAINS_1, { 0.5, 0.7 }, { 15, 3 } },
  { .SNOWY_FOREST, { 0.7, 0.8 }, { 12, 17 } },
  { .SNOWY_MOUNTAINS, { 0.8, 0.9 }, { 28, 3 } },
  { .VOLCANO, { 0.9, 1.2}, { 21, 9 } },
}

// Interval threshold between biomes.
// Used to calculate the "width" of the shared border.
@(private="file")
threshold: f32 = 0.03
