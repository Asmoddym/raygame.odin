package macro

import "core:log"
import "engine"
import rl "vendor:raylib"
import "terrain"


// Enums


// Scene IDs
SceneID :: enum {
  MAIN,
  PAUSE,
}

// Overlay IDs
OverlayID :: enum {
  CONTROLS,
  MINIMAP,
}


// Structs


// Main controls struct
Controls :: struct {
  mask_mode_toggled: bool,
  seed: u64,
  size: i32,
}

controls: Controls = { false, 16, 5 }


// Systems


// Main terrain draw system to draw with or without masks.
draw_terrain :: proc() {
  terrain.draw(draw_masks = controls.mask_mode_toggled)
}

// Discover the terrain on mouse hover.
discover_terrain :: proc() {
  delta := rl.GetMouseDelta()

  if delta.x != 0 || delta.y != 0 {
    coords := terrain.get_current_hovered_cell_coords()

    terrain.discover_circular_part(coords, 7)
  }
}


// MAIN
main :: proc() {
  context.logger = log.create_console_logger(.Debug, {.Level, .Time, .Short_File_Path, .Line, .Procedure, .Terminal_Color})

  when ODIN_DEBUG do rl.SetTraceLogLevel(rl.TraceLogLevel.ERROR)

  engine.init()

  engine.scene_create(SceneID.MAIN,  uses_camera = true)
  engine.scene_create(SceneID.PAUSE, uses_camera = false)
  engine.scene_set_current(SceneID.MAIN)

  engine.scene_overlay_create(SceneID.PAUSE, 0,
    dimension_ratios = [2]f32 { 0.9, 0.9 },
    position_hook = [2]f32 { 0.5, 0.5 },
    on_init = pause_init)
  engine.scene_overlay_create(SceneID.MAIN, OverlayID.CONTROLS,
    dimension_ratios = [2]f32 { 0.2, 0.5 },
    position_hook = [2]f32 { 0.9, 0.9 },
    on_init = overlay_init_controls)
  engine.scene_overlay_create(SceneID.MAIN, OverlayID.MINIMAP,
    width_ratio = 0.15,
    position_hook = [2]f32 { 0, 0 })

  engine.system_register(draw_terrain,                      { int(SceneID.MAIN) })
  engine.system_register(terrain.process_navigation,        { int(SceneID.MAIN) })
  engine.system_register(terrain.process_selection,         { int(SceneID.MAIN) })
  engine.system_register(discover_terrain,                  { int(SceneID.MAIN) })

  engine.system_overlay_register(overlay_system_draw,       { int(SceneID.MAIN) })
  engine.system_overlay_register(pause_overlay_system_draw, { int(SceneID.PAUSE) })

  terrain.generate(controls.size, controls.seed)

  // Has to be at the end because it changes the current scene
  engine.system_register(pause_system)
  engine.run()

  terrain.unload()
  engine.unload()
}
