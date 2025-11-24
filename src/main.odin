#+feature dynamic-literals

package macro

import "engine"
import "enums"
import "globals"
import rl "vendor:raylib"

BOX_SIZE: f32 = 64

init_npc :: proc() {
  npc := engine.database_create_entity()
  bounding_box := engine.database_add_component(npc, &table_bounding_boxes[1])
  bounding_box.box = rl.Rectangle { 100, 100, BOX_SIZE, BOX_SIZE }
  bounding_box.movable = false
  bounding_box.collidable = true
  bounding_box.layer = 1

  ui_animated_sprite_init(engine.database_add_component(npc, &table_animated_sprites[1]), {
    int(enums.Direction.NONE) = "idle.png",
    int(enums.Direction.UP) = "up.png",
    int(enums.Direction.DOWN) = "down.png",
    int(enums.Direction.LEFT) = "left.png",
    int(enums.Direction.RIGHT) = "right.png",
  }, enums.Direction.NONE)

  collectable := engine.database_add_component(npc, &table_collectables)
  collectable.metadata.pickup_text_box_id = 0
  collectable.metadata.interaction_text_box_id = 0

  collectable.interaction_text = "coucou je suis gentil"
  collectable.metadata.bounding_box = bounding_box
  collectable.keep_interaction_alive = false
}

init_player :: proc() {
  globals.player_id = engine.database_create_entity()
  bounding_box := engine.database_add_component(globals.player_id, &table_bounding_boxes[globals.PLAYER_LAYER])
  bounding_box.box = rl.Rectangle { 300, 300, BOX_SIZE, BOX_SIZE }
  bounding_box.movable = true
  bounding_box.collidable = true
  bounding_box.layer = globals.PLAYER_LAYER
  player_animated_sprite := engine.database_add_component(globals.player_id, &table_animated_sprites[globals.PLAYER_LAYER])

  ui_animated_sprite_init(player_animated_sprite, {
    int(enums.Direction.NONE) = "idle.png",
    int(enums.Direction.UP) = "up.png",
    int(enums.Direction.DOWN) = "down.png",
    int(enums.Direction.LEFT) = "left.png",
    int(enums.Direction.RIGHT) = "right.png",
  }, enums.Direction.NONE)

  engine.database_add_component(globals.player_id, &table_backpacks).has_npc = false
}

init_terrain :: proc() {
  tree_trunk_1 := engine.database_create_entity()
  engine.database_add_component(tree_trunk_1, &table_sprites[globals.PLAYER_LAYER]).texture = engine.assets_find_or_create(rl.Texture2D, "tree_trunk_1.png")
  tree_trunk_1_bb := engine.database_add_component(tree_trunk_1, &table_bounding_boxes[globals.PLAYER_LAYER])
  tree_trunk_1_bb.box = rl.Rectangle { 500, 500, BOX_SIZE, BOX_SIZE }
  tree_trunk_1_bb.movable = true
  tree_trunk_1_bb.collidable = true
  tree_trunk_1_bb.layer = globals.PLAYER_LAYER

  tree_trunk_2 := engine.database_create_entity()
  engine.database_add_component(tree_trunk_2, &table_sprites[globals.PLAYER_LAYER + 1]).texture = engine.assets_find_or_create(rl.Texture2D, "tree_trunk_2.png")
  tree_trunk_2_bb := engine.database_add_component(tree_trunk_2, &table_bounding_boxes[globals.PLAYER_LAYER + 1])
  tree_trunk_2_bb.box = rl.Rectangle { 500, 500 - BOX_SIZE, BOX_SIZE, BOX_SIZE }
  tree_trunk_2_bb.movable = false
  tree_trunk_2_bb.collidable = false
  tree_trunk_2_bb.layer = globals.PLAYER_LAYER + 1

  tree_leaves := engine.database_create_entity()
  engine.database_add_component(tree_leaves, &table_sprites[globals.PLAYER_LAYER + 1]).texture = engine.assets_find_or_create(rl.Texture2D, "tree_leaves.png")
  tree_leaves_bb := engine.database_add_component(tree_leaves, &table_bounding_boxes[globals.PLAYER_LAYER + 1])
  tree_leaves_bb.box = rl.Rectangle { 500 - (BOX_SIZE * 1) / 2, 500 - BOX_SIZE * 2 - BOX_SIZE, BOX_SIZE * 2, BOX_SIZE * 2}
  tree_leaves_bb.movable = false
  tree_leaves_bb.collidable = false
  tree_leaves_bb.layer = globals.PLAYER_LAYER + 1


  // Additional
  root := engine.database_create_entity()
  engine.database_add_component(root, &table_sprites[globals.PLAYER_LAYER]).texture = engine.assets_find_or_create(rl.Texture2D, "tree_trunk_1.png")
  root_bb := engine.database_add_component(root, &table_bounding_boxes[globals.PLAYER_LAYER])
  root_bb.box = rl.Rectangle { 650, 500, BOX_SIZE, BOX_SIZE }
  root_bb.movable = false
  root_bb.collidable = true
  root_bb.layer = globals.PLAYER_LAYER
}

main :: proc() {
  engine.init()

  engine.scene_create(enums.SceneID.MAIN,  uses_camera = true)
  engine.scene_create(enums.SceneID.PAUSE, uses_camera = false)
  engine.scene_set_current(enums.SceneID.MAIN)

  engine.scene_overlay_create(enums.SceneID.MAIN, enums.OverlayID.INVENTORY, width_ratio = 0.5, height_ratio = 0.1)

  engine.system_register(ui_system_update_camera_position,       { int(enums.SceneID.MAIN) })
  engine.system_register(ui_system_animated_sprite_update,       { int(enums.SceneID.MAIN) })
  engine.system_register(input_system_main,                      { int(enums.SceneID.MAIN) }, recurrence_in_ms = 10)
  engine.system_register(ui_system_text_box_update,              { int(enums.SceneID.MAIN) })
  engine.system_register(bounding_box_system_collision_resolver, { int(enums.SceneID.MAIN) })
  engine.system_register(ui_system_drawable_draw,                { int(enums.SceneID.MAIN) })
  engine.system_register(bounding_box_system_draw,               { int(enums.SceneID.MAIN) })
  engine.system_register(ui_system_text_box_draw,                { int(enums.SceneID.MAIN) })

  engine.system_overlay_register(overlay_system_draw,            { int(enums.SceneID.MAIN) })

  engine.system_register(pause_system_main)
  engine.system_register(pause_system_toggle)

  engine.system_register(collectable_system_main)

  init_npc()
  init_player()
  init_terrain()

  engine.run()
  engine.unload()
}
