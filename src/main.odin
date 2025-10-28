#+feature dynamic-literals

package macro

import "engine"
import "enums"
import "globals"

import rl "vendor:raylib"

init_npc :: proc() {
  npc := engine.database_create_entity()
  sprite := engine.database_add_component(npc, &table_sprites)
  sprite.texture = rl.LoadTexture("wabbit_alpha.png")
  bounding_box := engine.database_add_component(npc, &table_bounding_boxes)
  bounding_box.box = rl.Rectangle { 100, 100, f32(sprite.texture.width), f32(sprite.texture.height) }
  bounding_box.movable = false
  text := engine.database_add_component(npc, &table_text_boxes)
  ui_text_box_init(text,
    "J'ai terriblement faim à l'aide :(",
    font_size = 20,
    attached_to_entity_id = npc,
  )
}

init_player :: proc() {
  globals.player_id = engine.database_create_entity()
  engine.database_add_component(globals.player_id, &table_controllables)
  bounding_box := engine.database_add_component(globals.player_id, &table_bounding_boxes)
  bounding_box.box = rl.Rectangle { 300, 300, 64.0, 64.0 }
  bounding_box.movable = true
  player_animated_sprite := engine.database_add_component(globals.player_id, &table_animated_sprites)

  ui_animated_sprite_init(player_animated_sprite, {
    int(enums.Direction.NONE) = "idle.png",
    int(enums.Direction.UP) = "up.png",
    int(enums.Direction.DOWN) = "down.png",
    int(enums.Direction.LEFT) = "left.png",
    int(enums.Direction.RIGHT) = "right.png",
  })
}

main :: proc() {
  engine.init()

  engine.system_register(engine.SystemType.RUNTIME,  ui_system_update_camera_position)
  engine.system_register(engine.SystemType.RUNTIME,  ui_system_animated_sprite_update)
  engine.system_register(engine.SystemType.RUNTIME,  input_system_main)
  engine.system_register(engine.SystemType.RUNTIME,  controllable_system_handle_inputs, recurrence_in_ms = 10)
  engine.system_register(engine.SystemType.RUNTIME,  ui_system_text_box_update)
  engine.system_register(engine.SystemType.RUNTIME,  bounding_box_system_collision_resolver)
  engine.system_register(engine.SystemType.RUNTIME,  ui_system_sprite_draw)
  engine.system_register(engine.SystemType.RUNTIME,  ui_system_animated_sprite_draw)
  engine.system_register(engine.SystemType.RUNTIME,  ui_system_text_box_draw)
  engine.system_register(engine.SystemType.PAUSE,    pause_system_main)
  engine.system_register(engine.SystemType.INTERNAL, pause_system_toggle)

  init_npc()
  init_player()

  engine.run()
}
