package macro

import "enums"
import "engine"
import rl "vendor:raylib"


// Main overlay draw system, inventory only for now
overlay_system_draw :: proc() {
  overlay_subsystem_draw_inventory()
}

// Draw inventory subsystem
// TODO: Avoid having to always recreate the whole render texture
overlay_subsystem_draw_inventory :: proc() {
  overlay     := &engine.game_state.current_scene.overlays[int(enums.OverlayID.INVENTORY)]

  rl.BeginTextureMode(overlay.render_texture)
  rl.ClearBackground(rl.BLACK)

  // 1 and -2 are here to see the lines
  rl.DrawRectangleLines(1, 1, overlay.resolution.x - 1, overlay.resolution.y - 2, rl.WHITE)

  position: [2]f32 = {
    f32(engine.game_state.resolution.x - overlay.resolution.x),
    f32(engine.game_state.resolution.y - overlay.resolution.y),
  }

  font_size := i32(engine.game_state.resolution.x / 80)
  height := i32(rl.MeasureTextEx(rl.GetFontDefault(), "A", f32(font_size), 1).y)

  rl.DrawText(rl.TextFormat("Gold: %d", 0), 5, 5, font_size, rl.WHITE)
  rl.DrawText(rl.TextFormat("Wood: %d", 0), 5, 5 + 2 * height, font_size, rl.WHITE)
  rl.DrawText(rl.TextFormat("Stone: %d", 0), 5, 5 + 4 * height, font_size, rl.WHITE)

  rl.EndTextureMode()

  position.x -= 10
  position.y -= 10

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
