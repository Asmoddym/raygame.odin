package macro

import "core:fmt"
import "terrain"
import "engine"
import "ui"


// Main overlay draw system.
// engine.scene_overlay_draw will wrap the callback with BeginTextureMode and ClearBackground, frame the texture and render it.
overlay_system_draw :: proc() {
  engine.scene_overlay_draw(OverlayID.CONTROLS, draw_controls)
  engine.scene_overlay_draw(OverlayID.MINIMAP, draw_minimap)
}

overlay_init_controls :: proc(overlay: ^engine.Overlay) {
  // TODO: add an enum for IDs
  ui.simple_button_create(1, "Seed -", overlay, { 0.2, 0.1 })
  ui.simple_button_create(2, "Seed +", overlay, { 0.8, 0.1 })
  ui.simple_button_create(3, "Toggle mask mode", overlay, { 0.5, 0.4 })
  ui.simple_button_create(4, "Untoggle mask mode", overlay, { 0.5, 0.4 })
  ui.simple_button_create(5, "Size -", overlay, { 0.2, 0.2 })
  ui.simple_button_create(6, "Size +", overlay, { 0.8, 0.2 })
}

draw_controls :: proc(overlay: ^engine.Overlay) {
  clicked: bool        = false
  previous_controls   := controls

  // Seed buttons
  _, clicked = ui.simple_button_draw(1, overlay)
  if clicked do controls.seed -= 1

  _, clicked = ui.simple_button_draw(2, overlay)
  if clicked do controls.seed += 1

  // Mask mode buttons
  mask_mode_button_id := controls.mask_mode_toggled ? 4 : 3
  _, clicked = ui.simple_button_draw(mask_mode_button_id, overlay)
  if clicked do controls.mask_mode_toggled = !controls.mask_mode_toggled

  // Size buttons
  _, clicked = ui.simple_button_draw(5, overlay)
  if clicked do controls.size = max(controls.size - 1, 1)

  _, clicked = ui.simple_button_draw(6, overlay)
  if clicked do controls.size += 1

  if (
    previous_controls.seed != controls.seed ||
    previous_controls.size != controls.size
  ) {
    terrain.unload()
    terrain.generate(controls.size, controls.seed)
  }

  // TODO: make this into position_hooks
  ui.text_box_draw_fast(fmt.tprintf("Seed: %d", controls.seed), 5, 300)
  ui.text_box_draw_fast(fmt.tprintf("Size: %dx%d", controls.size, controls.size), 5, 300 + 20 + 2 * ui.default_font_height())
}

draw_minimap :: proc(overlay: ^engine.Overlay) {
  terrain.draw_in_overlay(overlay, controls.mask_mode_toggled)
}
