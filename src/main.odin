package macro

import "core:log"
import "engine"
import "enums"
import "terrain"

Controls :: struct {
  mask_mode_toggled: bool,
  seed: u64,
  size: i32,
}

controls: Controls = { false, 16, 5 }

draw_terrain :: proc() {
  terrain.draw(draw_masks = controls.mask_mode_toggled)
}

main :: proc() {
  context.logger = log.create_console_logger(.Debug, {.Level, .Time, .Short_File_Path, .Line, .Procedure, .Terminal_Color})

  engine.init()

  engine.scene_create(enums.SceneID.MAIN,  uses_camera = true)
  engine.scene_create(enums.SceneID.PAUSE, uses_camera = false)
  engine.scene_set_current(enums.SceneID.MAIN)

  engine.scene_overlay_create(enums.SceneID.PAUSE, 0,
    dimension_ratios = [2]f32 { 0.9, 0.9 },
    position_hook = [2]f32 { 0.5, 0.5 },
    on_init = pause_init)
  engine.scene_overlay_create(enums.SceneID.MAIN, enums.OverlayID.CONTROLS,
    dimension_ratios = [2]f32 { 0.2, 0.5 },
    position_hook = [2]f32 { 0.9, 0.9 },
    on_init = overlay_init_controls)
  engine.scene_overlay_create(enums.SceneID.MAIN, enums.OverlayID.MINIMAP,
    width_ratio = 0.15,
    position_hook = [2]f32 { 0, 0 })

  engine.system_register(draw_terrain,                      { int(enums.SceneID.MAIN) })
  engine.system_register(terrain.process_navigation,        { int(enums.SceneID.MAIN) })
  engine.system_register(terrain.process_selection,         { int(enums.SceneID.MAIN) })
  engine.system_register(game_update_resources,         { int(enums.SceneID.MAIN) })

  engine.system_overlay_register(overlay_system_draw,       { int(enums.SceneID.MAIN) })
  engine.system_overlay_register(pause_overlay_system_draw, { int(enums.SceneID.PAUSE) })

  terrain.generate(controls.size, controls.seed)

  // Has to be at the end because it changes the current scene
  engine.system_register(pause_system)
  engine.run()

  terrain.unload()
  engine.unload()
}
