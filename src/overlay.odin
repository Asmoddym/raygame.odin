package macro

import "enums"
import "engine"
import rl "vendor:raylib"


// Main overlay draw system, inventory only for now
overlay_system_draw :: proc() {
  overlay_subsystem_draw_inventory()
}

// Draw inventory subsystem
overlay_subsystem_draw_inventory :: proc() {
  overlay := &engine.game_state.current_scene.overlays[int(enums.OverlayID.INVENTORY)]

  rl.DrawTexturePro(overlay.render_texture.texture,
    rl.Rectangle { 0, 0, f32(overlay.resolution.x), -f32(overlay.resolution.y) },
    rl.Rectangle { overlay.position.x, overlay.position.y, f32(overlay.resolution.x), f32(overlay.resolution.y) },
    rl.Vector2 { 0, 0 }, 0, rl.WHITE)
}

// Init inventory overlay after instanciation or resolution change.
//
// The overlay is passed as a param because game_state.current_scene could be the pause scene, thus not containing the overlay.
// The overlay position is stored inside to avoid having to recalculate it everytime.
//
// TODO: Maybe store overlays in a separate registry instead of scenes directly, so that we can access them independently from the scene
// TODO: Maybe put the position calculation in the draw system? It may be useless to store it
overlay_init_inventory :: proc(overlay: ^engine.Overlay) {
  rl.BeginTextureMode(overlay.render_texture)

  // 1 and -2 are here to see the lines
  rl.DrawRectangle(0, 0, overlay.resolution.x, overlay.resolution.y, rl.BLACK)
  rl.DrawRectangleLines(1, 1, overlay.resolution.x - 1, overlay.resolution.y - 2, rl.WHITE)

  tiles := 5
  padding := int(f64(overlay.resolution.x) * PADDING_RATIO)
  tile_width: i32 = overlay.resolution.y - 2 * i32(padding)

  total_width := (tile_width + i32(padding)) * i32(tiles) - i32(padding)
  init_offset := overlay.resolution.x / 2 - total_width / 2

  for i in 0..<tiles {
    offset := init_offset + i32(i * (int(tile_width) + padding))

    rl.DrawRectangle(offset, i32(padding), tile_width, tile_width, rl.WHITE)
  }

  rl.EndTextureMode()

  overlay.position = {
    f32(engine.game_state.resolution.x / 2 - overlay.resolution.x / 2),
    f32(engine.game_state.resolution.y - overlay.resolution.y) - f32(overlay.resolution.y) * 0.1,
  }
}



//
// PRIVATE
//



@(private="file")
PADDING_RATIO := 0.01
