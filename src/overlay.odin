package macro

import "terrain"
import "enums"
import "engine"
import rl "vendor:raylib"


// Main overlay draw system, inventory only for now
overlay_system_draw :: proc() {
  engine.scene_overlay_draw(enums.OverlayID.INVENTORY, draw_inventory)
  engine.scene_overlay_draw(enums.OverlayID.MINIMAP, draw_minimap)
}

draw_inventory :: proc(overlay: ^engine.Overlay) {
  font_size := i32(engine.game_state.resolution.x / 80)
  height := i32(rl.MeasureTextEx(rl.GetFontDefault(), "A", f32(font_size), 1).y)

  rl.DrawText(rl.TextFormat("Gold: %d", _game.resources.gold), 5, 5, font_size, rl.WHITE)
  rl.DrawText(rl.TextFormat("Wood: %d", _game.resources.wood), 5, 5 + 2 * height, font_size, rl.WHITE)
  rl.DrawText(rl.TextFormat("Stone: %d", _game.resources.stone), 5, 5 + 4 * height, font_size, rl.WHITE)
}

draw_minimap :: proc(overlay: ^engine.Overlay) {
  @(static) camera: rl.Camera2D = { { 0, 0 }, { 0, 0 }, 0, 0 }

  camera.zoom = f32(overlay.resolution.x) / terrain.map_side_pixel_size()
  rl.BeginMode2D(camera)

  terrain.draw_whole_map()

  rl.EndMode2D()
}



//
// PRIVATE
//



@(private="file")
PADDING_RATIO := 0.01

