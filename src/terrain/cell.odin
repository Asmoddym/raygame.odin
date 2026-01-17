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


// Generate the terrain cell at the given x and y coords.
generate_cell :: proc(#any_int x, y: i32) -> TerrainCell {
  detail_value, base_altitude_value, altitude: f32
  altitude = 0

  biome_value := generate_biome_value(x, y)
  base_altitude_value = generate_base_altitude_value(x, y)
  detail_value = generate_detail_value(x, y)

  altitude += 2.0 * detail_value - 1
  altitude += base_altitude_value

  return create_terrain_cell(y, x, altitude, biome_value, base_altitude_value, detail_value)
}

// Single cell creation.
// Will iterate through the biomes and apply a tileset position to the cell.
@(private="file")
create_terrain_cell :: proc(y, x: i32, altitude, biome_value, base_altitude_value, detail_value: f32) -> TerrainCell {
  tileset_pos: [2]i32 = { -1, -1 }

  altitude_overlap_interval: [2]f32 = { altitude - layer_threshold, altitude + layer_threshold }

  // biome_overlap_interval: [2]f32 = { biome_value - biome_threshold, biome_value + biome_threshold }
  // biome: ^BiomeDescriptor = &biome_descriptors[0]
  // for idx in 0..<len(biome_descriptors) {
  //   current_biome := &biome_descriptors[idx]
  //
  //   // Very naive approach but if kinda works for forest patches
  //   if biome_overlap_interval.x >= current_biome.interval.x && biome_overlap_interval.y < current_biome.interval.y {
  //     biome = &biome_descriptors[idx]
  //   }
  // }
  //

  biome := &BIOME

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
generate_base_altitude_value :: proc(x, y: i32) -> f32 {
  base_altitude_value := perlin_noise.octave_perlin(&_handle.default_noise_handle, x, y, noise_scale = 0.004, persistence = 0.4)

  return math.remap_clamped(base_altitude_value, 0, 1, -2, 2) + 0.1
}

// Detail value generation using default_noise_handle.
@(private="file")
generate_detail_value :: proc(x, y: i32) -> f32 {
  return perlin_noise.octave_perlin(&_handle.default_noise_handle, x, y, noise_scale = 0.015, persistence = 0.5)
}

// Biome value generation using biome_noise_handle.
// Not very detailed and used for some additional details such as forest patches.
@(private="file")
generate_biome_value :: proc(x, y: i32) -> f32 {
  return perlin_noise.octave_perlin(&_handle.biome_noise_handle, x, y, noise_scale = 0.015, persistence = 0.3)
}


// LOCAL CONSTANTS


// Interval layer_threshold between biome layers.
// Used to calculate the "width" of the shared border.
@(private="file")
layer_threshold: f32 = 0.01

// Interval layer_threshold between biomes.
// Used to calculate the "width" of the shared border.
@(private="file")
biome_threshold: f32 = 0.02
