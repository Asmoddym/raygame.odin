package macro

import "enums"
import "engine"
import "globals"
import rl "vendor:raylib"


// Main overlay draw system, inventory only for now
overlay_system_draw :: proc() {
  overlay_subsystem_draw_inventory()
}

// Draw inventory subsystem
overlay_subsystem_draw_inventory :: proc() {
  overlay := &engine.game_state.current_scene.overlays[int(enums.OverlayID.INVENTORY)]

  tiles := 5
  padding := int(f64(overlay.resolution.x) * PADDING_RATIO)
  tile_width: i32 = overlay.resolution.y - 2 * i32(padding)
  total_width := (tile_width + i32(padding)) * i32(tiles) - i32(padding)
  init_offset := overlay.resolution.x / 2 - total_width / 2

  rl.BeginTextureMode(overlay.render_texture)
  rl.ClearBackground(rl.BLACK)

  // 1 and -2 are here to see the lines
  rl.DrawRectangleLines(1, 1, overlay.resolution.x - 1, overlay.resolution.y - 2, rl.WHITE)

  for i in 0..<tiles {
    offset := init_offset + i32(i * (int(tile_width) + padding))

    rl.DrawRectangleLines(offset, i32(padding), tile_width, tile_width, rl.WHITE)
    if i == 0 && engine.database_get_component(globals.player_id, &table_backpacks).has_npc {
    rl.DrawRectangle(offset, i32(padding), tile_width, tile_width, rl.PURPLE)
    }
  }

  rl.EndTextureMode()

  position: [2]f32 = {
    f32(engine.game_state.resolution.x / 2 - overlay.resolution.x / 2),
    // - f32(overlay.resolution.y) * 0.1 is here to set a little dynamic margin at the bottom
    f32(engine.game_state.resolution.y - overlay.resolution.y) - f32(overlay.resolution.y) * 0.1,
  }

  rl.DrawTexturePro(overlay.render_texture.texture,
    rl.Rectangle { 0, 0, f32(overlay.resolution.x), -f32(overlay.resolution.y) },
    rl.Rectangle { position.x, position.y, f32(overlay.resolution.x), f32(overlay.resolution.y) },
    rl.Vector2 { 0, 0 }, 0, rl.WHITE)
}



//
// PRIVATE
//



@(private="file")
PADDING_RATIO := 0.01
