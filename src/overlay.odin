package macro

import "core:log"
import "terrain"
import "enums"
import "engine"
import rl "vendor:raylib"


// Main overlay draw system, inventory only for now
overlay_system_draw :: proc() {
  overlay_subsystem_draw_inventory()
  overlay_subsystem_draw_minimap()
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

  rl.DrawText(rl.TextFormat("Gold: %d", _game.resources.gold), 5, 5, font_size, rl.WHITE)
  rl.DrawText(rl.TextFormat("Wood: %d", _game.resources.wood), 5, 5 + 2 * height, font_size, rl.WHITE)
  rl.DrawText(rl.TextFormat("Stone: %d", _game.resources.stone), 5, 5 + 4 * height, font_size, rl.WHITE)

  rl.EndTextureMode()

  position.x -= 10
  position.y -= 10

  rl.DrawTexturePro(overlay.render_texture.texture,
    rl.Rectangle { 0, 0, f32(overlay.resolution.x), -f32(overlay.resolution.y) },
    rl.Rectangle { position.x, position.y, f32(overlay.resolution.x), f32(overlay.resolution.y) },
    rl.Vector2 { 0, 0 }, 0, rl.WHITE)
}

overlay_subsystem_draw_minimap :: proc() {
  @(static) camera: rl.Camera2D = { { 0, 0 }, { 0, 0 }, 0, 0 }

  overlay     := &engine.game_state.current_scene.overlays[int(enums.OverlayID.MINIMAP)]
  camera.zoom = f32(overlay.resolution.x) / (50 * 16 * 5)

  rl.BeginTextureMode(overlay.render_texture)
  rl.BeginMode2D(camera)
  rl.ClearBackground(rl.BLACK)

  terrain.draw_whole_map()

  rl.EndMode2D()
  rl.DrawRectangleLines(1, 1, overlay.resolution.x - 1, overlay.resolution.y - 2, rl.WHITE)
  rl.EndTextureMode()

  position: [2]f32 = { 10, 10 }

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



