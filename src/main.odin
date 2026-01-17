package macro

import "core:fmt"
import "core:log"
import "engine"
import "enums"
import "bounding_box"
import "globals"
import "ui"
import rl "vendor:raylib"
import "terrain"

main :: proc() {
  context.logger = log.create_console_logger(.Debug, {.Level, .Time, .Short_File_Path, .Line, .Procedure, .Terminal_Color})

  engine.init()

  engine.scene_create(enums.SceneID.MAIN,  uses_camera = true)
  engine.scene_create(enums.SceneID.PAUSE, uses_camera = false)
  engine.scene_set_current(enums.SceneID.MAIN)

  engine.scene_overlay_create(enums.SceneID.MAIN, enums.OverlayID.INVENTORY, width_ratio = 0.5, height_ratio = 0.1)
  // engine.scene_overlay_create(enums.SceneID.MAIN, enums.OverlayID.CRAFT, width_ratio = 0.6, height_ratio = 0.6)

  engine.system_register(terrain.draw,                              { int(enums.SceneID.MAIN) })
  // engine.system_register(terrain.system_manipulation,               { int(enums.SceneID.MAIN) })

  // engine.system_register(ui.system_text_box_update,              { int(enums.SceneID.MAIN) })
  // engine.system_register(bounding_box.system_collision_resolver, { int(enums.SceneID.MAIN) })
  // engine.system_register(drawable_system_draw,                   { int(enums.SceneID.MAIN) })
  // engine.system_register(bounding_box.system_draw,               { int(enums.SceneID.MAIN) })
  // engine.system_register(ui.system_text_box_draw,                { int(enums.SceneID.MAIN) })

  // engine.system_register(ui.system_update_camera_position,       { int(enums.SceneID.MAIN) })
  // engine.system_register(drawable_system_animated_sprite_update,       { int(enums.SceneID.MAIN) })
  // engine.system_register(input_system_player_movement,           { int(enums.SceneID.MAIN) }, recurrence_in_ms = 10)
  // engine.system_overlay_register(overlay_system_draw,            { int(enums.SceneID.MAIN) })
  // engine.system_register(collectable_system_main)

  engine.system_register(pause_system_main)
  engine.system_register(pause_system_toggle)

  engine.system_register(terrain.process_inputs)

  terrain.generate(5)

  engine.run()

  terrain.unload()
  engine.unload()
}
