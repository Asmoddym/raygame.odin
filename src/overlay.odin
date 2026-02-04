package macro

import "terrain"
import "enums"
import "engine"
import "ui"
import rl "vendor:raylib"


// Main overlay draw system.
// engine.scene_overlay_draw will wrap the callback with BeginTextureMode and ClearBackground, frame the texture and render it.
overlay_system_draw :: proc() {
  engine.scene_overlay_draw(enums.OverlayID.INVENTORY, draw_inventory)
  engine.scene_overlay_draw(enums.OverlayID.MINIMAP, draw_minimap)
  engine.scene_overlay_draw(1234, draw_test)
}

draw_test :: proc(overlay: ^engine.Overlay) {
  ui.simple_button_draw("a", { 5, f32(overlay.resolution.y - 50), overlay }, 12)
}

draw_inventory :: proc(overlay: ^engine.Overlay) {
  @(static) button_selected := false

  font_size := i32(engine.game_state.resolution.x / 80)
  height := i32(rl.MeasureTextEx(rl.GetFontDefault(), "A", f32(font_size), 1).y)

  // TODO:
  // - use position hooks for this
  // - make 1 hook for X and 1 for Y? Maybe later
  ui.simple_button_draw("coucoucoucou", { 0.5, 0.1, overlay }, font_size)

  rl.DrawText(rl.TextFormat("Gold: %d", _game.resources.gold), 5, 5, font_size, rl.WHITE)
  rl.DrawText(rl.TextFormat("Wood: %d", _game.resources.wood), 5, 5 + 2 * height, font_size, rl.WHITE)
  rl.DrawText(rl.TextFormat("Stone: %d", _game.resources.stone), 5, 5 + 4 * height, font_size, rl.WHITE)
}

draw_minimap :: proc(overlay: ^engine.Overlay) {
  @(static) camera: rl.Camera2D = { { 0, 0 }, { 0, 0 }, 0, 0 }

  camera.zoom = f32(overlay.resolution.x) / terrain.f32_map_side_pixel_size()

  // Using this updates the engine.current_camera pointer
  engine.camera_set_current_camera(&camera)

  terrain.draw_whole_map()

  rl.EndMode2D()
}
