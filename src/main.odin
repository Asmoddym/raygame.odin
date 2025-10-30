#+feature dynamic-literals

package macro

import "engine"
import "enums"
import "globals"

import rl "vendor:raylib"

init_npc :: proc() {
  npc := engine.database_create_entity()
  sprite := engine.database_add_component(npc, &table_sprites[1])
  sprite.texture = rl.LoadTexture("wabbit_alpha.png")
  bounding_box := engine.database_add_component(npc, &table_bounding_boxes[1])
  bounding_box.box = rl.Rectangle { 100, 100, f32(sprite.texture.width), f32(sprite.texture.height) }
  bounding_box.movable = false
  bounding_box.collidable = true
  text := engine.database_add_component(npc, &table_text_boxes)
  ui_text_box_init(text,
    "J'ai terriblement faim à l'aide :(",
    font_size = 20,
    attached_to_bounding_box = bounding_box,
  )
}

init_player :: proc() {
  globals.player_id = engine.database_create_entity()
  engine.database_add_component(globals.player_id, &table_controllables)
  bounding_box := engine.database_add_component(globals.player_id, &table_bounding_boxes[0])
  bounding_box.box = rl.Rectangle { 300, 300, 64.0, 64.0 }
  bounding_box.movable = true
  bounding_box.collidable = true
  player_animated_sprite := engine.database_add_component(globals.player_id, &table_animated_sprites[0])

  ui_animated_sprite_init(player_animated_sprite, {
    int(enums.Direction.NONE) = "idle.png",
    int(enums.Direction.UP) = "up.png",
    int(enums.Direction.DOWN) = "down.png",
    int(enums.Direction.LEFT) = "left.png",
    int(enums.Direction.RIGHT) = "right.png",
  })
}

init_terrain :: proc() {
  tree_trunk_1 := engine.database_create_entity()
  engine.database_add_component(tree_trunk_1, &table_sprites[0]).texture = rl.LoadTexture("tree_trunk_1.png")
  tree_trunk_1_bb := engine.database_add_component(tree_trunk_1, &table_bounding_boxes[0])
  tree_trunk_1_bb.box = rl.Rectangle { 500, 500, 64, 64 }
  tree_trunk_1_bb.movable = true
  tree_trunk_1_bb.collidable = true

  root := engine.database_create_entity()
  engine.database_add_component(root, &table_sprites[0]).texture = rl.LoadTexture("tree_trunk_2.png")
  root_bb := engine.database_add_component(root, &table_bounding_boxes[0])
  root_bb.box = rl.Rectangle { 650, 500, 64, 64 }
  root_bb.movable = false
  root_bb.collidable = true


  tree_trunk_2 := engine.database_create_entity()
  engine.database_add_component(tree_trunk_2, &table_sprites[1]).texture = rl.LoadTexture("tree_trunk_2.png")
  tree_trunk_2_bb := engine.database_add_component(tree_trunk_2, &table_bounding_boxes[1])
  tree_trunk_2_bb.box = rl.Rectangle { 500, 500 - 64, 64, 64 }
  tree_trunk_2_bb.movable = false
  tree_trunk_2_bb.collidable = false

  tree_leaves := engine.database_create_entity()
  engine.database_add_component(tree_leaves, &table_sprites[1]).texture = rl.LoadTexture("tree_leaves.png")
  tree_leaves_bb := engine.database_add_component(tree_leaves, &table_bounding_boxes[1])
  tree_leaves_bb.box = rl.Rectangle { 500 - 32, 500 - 128 - 64, 128, 128}
  tree_leaves_bb.movable = false
  tree_leaves_bb.collidable = false
}

main :: proc() {
  engine.init()

  engine.system_register(engine.SystemType.RUNTIME,  ui_system_update_camera_position)
  engine.system_register(engine.SystemType.RUNTIME,  ui_system_animated_sprite_update)
  engine.system_register(engine.SystemType.RUNTIME,  input_system_main)
  engine.system_register(engine.SystemType.RUNTIME,  controllable_system_handle_inputs, recurrence_in_ms = 10)
  engine.system_register(engine.SystemType.RUNTIME,  ui_system_text_box_update)
  engine.system_register(engine.SystemType.RUNTIME,  bounding_box_system_collision_resolver)
  engine.system_register(engine.SystemType.RUNTIME,  ui_system_drawable_draw)
  engine.system_register(engine.SystemType.RUNTIME,  bounding_box_system_draw)
  engine.system_register(engine.SystemType.RUNTIME,  ui_system_text_box_draw)
  engine.system_register(engine.SystemType.PAUSE,    pause_system_main)
  engine.system_register(engine.SystemType.INTERNAL, pause_system_toggle)

  init_npc()
  init_player()
  init_terrain()

  engine.run()
}
