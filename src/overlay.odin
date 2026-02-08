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
  font_size := i32(engine.game_state.resolution.x / 80)

  ui.simple_button_draw("hello",  overlay, { 0, 0 }, font_size)
  ui.simple_button_draw("we've been expecting you",  overlay, { 0.5, 0.5 }, font_size)
  ui.simple_button_draw("there general kenobi",  overlay, { 1, 1 }, font_size)
}

draw_inventory :: proc(overlay: ^engine.Overlay) {
  @(static) button_selected := false

  font_size := i32(engine.game_state.resolution.x / 80)
  height := i32(rl.MeasureTextEx(rl.GetFontDefault(), "A", f32(font_size), 1).y)

  // TODO:
  // - Make a system to detect if the mouse is above an overlay (to prevent the terrain to move for ex)
  _, clicked := ui.simple_button_draw("coucoucoucou", overlay, { 0.5, 0.5 }, font_size)

  if clicked do _game.resources.wood += 1

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
