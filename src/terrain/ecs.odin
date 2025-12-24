package terrain

import "../engine"
import "../lib/perlin_noise"
import rl "vendor:raylib"


// Main terrain component.
// Might be used with a different scale for minimap?
Component_Terrain :: struct {
  using base: engine.Component(engine.Metadata),
  handle: Handle,
}

table_terrains: engine.Table(Component_Terrain)


// PROCS


// Init terrain.
// No params for now but maybe later if I make it more generic
init :: proc() {
  tileset         := engine.assets_find_or_create(rl.Texture2D, "tileset/Tileset_Compressed_B_NoAnimation.png")
  component       := engine.database_add_component(engine.database_create_entity(), &table_terrains)
  component.handle = initialize_handle(50, 50, tileset)

  perlin_noise.repermutate(&component.handle.biome_noise_handle)
  perlin_noise.repermutate(&component.handle.default_noise_handle)

  for y in 0..<max_chunks_per_line {
    for x in 0..<max_chunks_per_line {
      generate_chunk(&component.handle, x, y)
    }
  }
}


// SYSTEMS


// Main draw system.
system_draw :: proc() {
  for &terrain in table_terrains.items {
    handle := &terrain.handle

      for &c in handle.chunks {
        // Using this method to invert the texture as that's the way Raylib works
        rl.DrawTextureRec(
          c.render_texture.texture,
          rl.Rectangle {
            0, 0,
            f32(handle.chunk_size.x * int(handle.displayed_tile_size)),
            -f32(handle.chunk_size.y * int(handle.displayed_tile_size)) },
            rl.Vector2 {
              f32(c.position.x * handle.chunk_size.x) * f32(handle.displayed_tile_size),
              f32(c.position.y * handle.chunk_size.y) * f32(handle.displayed_tile_size),
            },
            rl.WHITE,
        )
      }
  }
}



//
// PRIVATE
//



// CONSTANTS


// Max chunks for the map
@(private="file")
max_chunks_per_line := 10
