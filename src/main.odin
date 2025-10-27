#+feature dynamic-literals

package macro

import "engine"
import "enums"
import "globals"

import rl "vendor:raylib"

main :: proc() {
  engine.init()

  engine.systems_register(engine.SystemType.RUNTIME, update_camera_position)
  engine.systems_register(engine.SystemType.RUNTIME, update_animated_sprites)
  engine.systems_register(engine.SystemType.RUNTIME, handle_inputs)
  engine.systems_register(engine.SystemType.RUNTIME, move_controllable, recurrence_in_ms = 10)
  engine.systems_register(engine.SystemType.RUNTIME, update_texts)
  engine.systems_register(engine.SystemType.RUNTIME, collision_system)
  engine.systems_register(engine.SystemType.RUNTIME, draw_sprites) 
  engine.systems_register(engine.SystemType.RUNTIME, draw_animated_sprites) 
  engine.systems_register(engine.SystemType.RUNTIME, draw_texts) 
  engine.systems_register(engine.SystemType.PAUSE, pause_system)

  // NPC
  npc := engine.database_create_entity()
  sprite := engine.database_add_component(npc, &table_sprites)
  sprite.texture = rl.LoadTexture("wabbit_alpha.png")
  engine.database_add_component(npc, &table_bounding_boxes).box = rl.Rectangle { 100, 100, f32(sprite.texture.width), f32(sprite.texture.height) }
  text := engine.database_add_component(npc, &table_text_boxes)
  init_text_box(text,
    "J'ai terriblement faim à l'aide :(",
    font_size = 20,
    attached_to_entity_id = npc,
  )

  // Player
  globals.player = engine.database_create_entity()
  engine.database_add_component(globals.player, &table_controllables)
  engine.database_add_component(globals.player, &table_movables)
  engine.database_add_component(globals.player, &table_bounding_boxes).box = rl.Rectangle { 300, 300, 64.0, 64.0 }
  player_animated_sprite := engine.database_add_component(globals.player, &table_animated_sprites)

  animated_sprite_init(player_animated_sprite, {
    int(enums.Direction.NONE) = "idle.png",
    int(enums.Direction.UP) = "up.png",
    int(enums.Direction.DOWN) = "down.png",
    int(enums.Direction.LEFT) = "left.png",
    int(enums.Direction.RIGHT) = "right.png",
  })

  engine.run()
}
