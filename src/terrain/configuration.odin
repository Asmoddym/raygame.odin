#+feature dynamic-literals

package terrain

// Zoom speed
ZOOM_SPEED: f32 = 0.05

// Zoom interval
ZOOM_INTERVAL: [2]f32 = { 0.1, 3 }


TILE_SIZE: i32 = 16
F32_TILE_SIZE: f32 = f32(TILE_SIZE)

CHUNK_SIZE: i32 = 50
F32_CHUNK_SIZE: f32 = f32(CHUNK_SIZE)

CHUNK_PIXEL_SIZE := TILE_SIZE * CHUNK_SIZE

F32_CHUNK_PIXEL_SIZE := F32_CHUNK_SIZE * F32_TILE_SIZE

TILESET_PATH: cstring = "tileset/Tileset_Compressed_B_NoAnimation.png"


// ENUMS


// All available biome types.
BiomeType :: enum {
  PLAINS,
  BIOMES,
}

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


// STRUCT


// Internal descriptor for biomes
BiomeDescriptor :: struct {
  layers: [dynamic]LayerDescriptor,
}

// Internal descriptor for biome layers
LayerDescriptor :: struct {
  type: TerrainCellType,
  interval: [2]f32,
  tileset_position: [2]i32,
}

// Main biome descriptor.
BIOME: BiomeDescriptor = {
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
}
