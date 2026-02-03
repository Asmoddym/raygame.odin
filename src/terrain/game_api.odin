package terrain

import "core:slice"
import "core:math"


// Discovers a circular part of the map, given a radius and a position
discover_circular_part :: proc(position: [2]i32, radius: i32) {
  chunks_to_reload: [dynamic]int

  for i: f32 = 0; i < 90 ; i += 5 {
    cos_i := i32(f32(radius) * math.cos(i * math.PI / 90))
    sin_i := i32(f32(radius) * math.sin(i * math.PI / 90))

    directions: [4][2]i32 = {
      { position.x + cos_i, position.y + sin_i },
      { position.x + cos_i, position.y - sin_i },
      { position.x - cos_i, position.y + sin_i },
      { position.x - cos_i, position.y - sin_i },
    }

    for &direction in directions {
      tile_idx, chunk_idx := coords_to_tile_and_chunk_index(direction)
      discover_tile_from_idx(tile_idx)

      if !slice.contains(chunks_to_reload[:], chunk_idx) do append(&chunks_to_reload, chunk_idx)
    }

    for tmp_y in directions[1][1]..<directions[0][1] {
      tile_idx, _ := coords_to_tile_and_chunk_index({ directions[0][0], tmp_y })
      discover_tile_from_idx(tile_idx)
    }
  }

  for &c in chunks_to_reload {
    draw_mask_chunk(&_handle.display_chunks[c])
  }
}



// PRIVATE



// Discover a tile from its index, with a safe guard on out-of-bounds.
@(private="file")
discover_tile_from_idx :: proc(idx: int) {
  if idx < 0 || idx > len(_handle.tiles) do return

  _handle.tiles[idx].discovered = true
}
