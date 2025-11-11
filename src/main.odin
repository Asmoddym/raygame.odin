#+feature dynamic-literals

package macro

import "engine"
import "enums"
import "globals"
import rl "vendor:raylib"

init_npc :: proc() {
  npc := engine.database_create_entity()
  bounding_box := engine.database_add_component(npc, &table_bounding_boxes[1])
  bounding_box.box = rl.Rectangle { 100, 100, 64, 64 }
  bounding_box.movable = false
  bounding_box.collidable = true
  ui_text_box_draw(
    "J'ai terriblement faim à l'aide :(",
    font_size = 20,
    attached_to_bounding_box = bounding_box,
  )
  ui_animated_sprite_init(engine.database_add_component(npc, &table_animated_sprites[1]), {
    int(enums.Direction.NONE) = "idle.png",
    int(enums.Direction.UP) = "up.png",
    int(enums.Direction.DOWN) = "down.png",
    int(enums.Direction.LEFT) = "left.png",
    int(enums.Direction.RIGHT) = "right.png",
  })
}

init_player :: proc() {
  globals.player_id = engine.database_create_entity()
  bounding_box := engine.database_add_component(globals.player_id, &table_bounding_boxes[globals.PLAYER_LAYER])
  bounding_box.box = rl.Rectangle { 300, 300, 64.0, 64.0 }
  bounding_box.movable = true
  bounding_box.collidable = true
  player_animated_sprite := engine.database_add_component(globals.player_id, &table_animated_sprites[globals.PLAYER_LAYER])

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
  engine.database_add_component(tree_trunk_1, &table_sprites[globals.PLAYER_LAYER]).texture = engine.assets_find_or_create(rl.Texture2D, "tree_trunk_1.png")
  tree_trunk_1_bb := engine.database_add_component(tree_trunk_1, &table_bounding_boxes[globals.PLAYER_LAYER])
  tree_trunk_1_bb.box = rl.Rectangle { 500, 500, 64, 64 }
  tree_trunk_1_bb.movable = true
  tree_trunk_1_bb.collidable = true

  tree_trunk_2 := engine.database_create_entity()
  engine.database_add_component(tree_trunk_2, &table_sprites[globals.PLAYER_LAYER + 1]).texture = engine.assets_find_or_create(rl.Texture2D, "tree_trunk_2.png")
  tree_trunk_2_bb := engine.database_add_component(tree_trunk_2, &table_bounding_boxes[globals.PLAYER_LAYER + 1])
  tree_trunk_2_bb.box = rl.Rectangle { 500, 500 - 64, 64, 64 }
  tree_trunk_2_bb.movable = false
  tree_trunk_2_bb.collidable = false

  tree_leaves := engine.database_create_entity()
  engine.database_add_component(tree_leaves, &table_sprites[globals.PLAYER_LAYER + 1]).texture = engine.assets_find_or_create(rl.Texture2D, "tree_leaves.png")
  tree_leaves_bb := engine.database_add_component(tree_leaves, &table_bounding_boxes[globals.PLAYER_LAYER + 1])
  tree_leaves_bb.box = rl.Rectangle { 500 - 32, 500 - 128 - 64, 128, 128}
  tree_leaves_bb.movable = false
  tree_leaves_bb.collidable = false


  // Additional
  root := engine.database_create_entity()
  engine.database_add_component(root, &table_sprites[globals.PLAYER_LAYER]).texture = engine.assets_find_or_create(rl.Texture2D, "tree_trunk_1.png")
  root_bb := engine.database_add_component(root, &table_bounding_boxes[globals.PLAYER_LAYER])
  root_bb.box = rl.Rectangle { 650, 500, 64, 64 }
  root_bb.movable = false
  root_bb.collidable = true
}


interface_system_draw :: proc() {
  @(static) panel := 0

  if rl.IsKeyPressed(rl.KeyboardKey.TAB) do panel = 1
  if rl.IsKeyPressed(rl.KeyboardKey.ESCAPE) do panel = 0
}

main :: proc() {
  engine.init()

  engine.system_register(engine.SystemType.RUNTIME,   ui_system_update_camera_position)
  engine.system_register(engine.SystemType.RUNTIME,   ui_system_animated_sprite_update)
  engine.system_register(engine.SystemType.RUNTIME,   input_system_main, recurrence_in_ms = 10)
  engine.system_register(engine.SystemType.RUNTIME,   ui_system_text_box_update)
  engine.system_register(engine.SystemType.RUNTIME,   bounding_box_system_collision_resolver)
  engine.system_register(engine.SystemType.RUNTIME,   ui_system_drawable_draw)
  engine.system_register(engine.SystemType.RUNTIME,   bounding_box_system_draw)
  engine.system_register(engine.SystemType.RUNTIME,   ui_system_text_box_draw)
  engine.system_register(engine.SystemType.OVERLAY,     overlay_system_main)
  engine.system_register(engine.SystemType.INTERNAL,  overlay_system_toggle)
  // engine.system_register(engine.SystemType.INTERFACE, interface_system_draw)

  init_npc()
  init_player()
  init_terrain()

  engine.run()
  engine.unload()
}
