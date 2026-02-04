package macro

import "core:log"
import "engine"
import "enums"
import "terrain"

main :: proc() {
  context.logger = log.create_console_logger(.Debug, {.Level, .Time, .Short_File_Path, .Line, .Procedure, .Terminal_Color})

  engine.init()

  engine.scene_create(enums.SceneID.MAIN,  uses_camera = true)
  engine.scene_create(enums.SceneID.PAUSE, uses_camera = false)
  engine.scene_set_current(enums.SceneID.MAIN)

  engine.scene_overlay_create(enums.SceneID.MAIN, enums.OverlayID.INVENTORY, [2]f32 { 0.25, 0.5 }, engine.Position.DOWN_RIGHT)
  engine.scene_overlay_create(enums.SceneID.MAIN, enums.OverlayID.MINIMAP, 0.15, engine.Position.UP_LEFT)

  // OLD STUFF
  //
  // engine.system_register(terrain.system_manipulation,               { int(enums.SceneID.MAIN) })
  // engine.system_register(ui.system_text_box_update,              { int(enums.SceneID.MAIN) })
  // engine.system_register(bounding_box.system_collision_resolver, { int(enums.SceneID.MAIN) })
  // engine.system_register(drawable_system_draw,                   { int(enums.SceneID.MAIN) })
  // engine.system_register(bounding_box.system_draw,               { int(enums.SceneID.MAIN) })
  // engine.system_register(ui.system_text_box_draw,                { int(enums.SceneID.MAIN) })
  // engine.system_register(ui.system_update_camera_position,       { int(enums.SceneID.MAIN) })
  // engine.system_register(drawable_system_animated_sprite_update,       { int(enums.SceneID.MAIN) })
  // engine.system_register(input_system_player_movement,           { int(enums.SceneID.MAIN) }, recurrence_in_ms = 10)
  // engine.system_register(collectable_system_main)



  // engine.system_overlay_register(overlay_system_draw,   { int(enums.SceneID.MAIN) })
  engine.system_register(terrain.draw,                  { int(enums.SceneID.MAIN) })
  engine.system_register(terrain.process_navigation,    { int(enums.SceneID.MAIN) })
  engine.system_register(terrain.process_selection,     { int(enums.SceneID.MAIN) })

  engine.system_register(overlay_system_draw,           { int(enums.SceneID.MAIN) })

  engine.system_register(game_update_resources, recurrence_in_ms = 100)
  terrain.generate(5)

  // Has to be at the end because it changes the current scene
  engine.system_register(pause_system)
  engine.run()

  terrain.unload()
  engine.unload()
}
