#+feature dynamic-literals

package macro

import "core:os"
import "core:fmt"
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
  collectable.interaction_text = "coucou je suis gentil"
  collectable.metadata.pickup_text_box_id = 0
  collectable.metadata.interaction_text_box_id = 0
  collectable.metadata.bounding_box = bounding_box
  collectable.metadata.keep_interaction_alive = false

  engine.database_add_component(npc, &table_backpacks).items = { .FLOWER }
}

init_player :: proc() {
  globals.player_id = engine.database_create_entity()
  bounding_box := engine.database_add_component(globals.player_id, &table_bounding_boxes[globals.PLAYER_LAYER])
  bounding_box.box = rl.Rectangle { 300, 300, BOX_SIZE, BOX_SIZE }
  bounding_box.movable = true
  bounding_box.collidable = true
  bounding_box.layer = globals.PLAYER_LAYER
  player_animated_sprite := engine.database_add_component(globals.player_id, &table_animated_sprites[globals.PLAYER_LAYER])
  engine.database_add_component(globals.player_id, &table_backpacks).max_items = 5

  ui_animated_sprite_init(player_animated_sprite, {
    int(enums.Direction.NONE) = "idle.png",
    int(enums.Direction.UP) = "up.png",
    int(enums.Direction.DOWN) = "down.png",
    int(enums.Direction.LEFT) = "left.png",
    int(enums.Direction.RIGHT) = "right.png",
  }, enums.Direction.NONE)
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

import "lib/perlin_noise"
import math "core:math"


max_chunks_per_line := 1

TerrainChunk :: struct {
  rt: rl.RenderTexture,
  position: [2]int,
}

main :: proc() {
  engine.init()

  terrain: [dynamic][dynamic]perlin_noise.TerrainCell
  // terrain := perlin_noise.generate(engine.game_state.resolution.x, engine.game_state.resolution.y)
  last_generated_at:= 0

  scale: i32= 1
  noise_scale: f32 = 0.015


  tileset := engine.assets_find_or_create(rl.Texture2D, "tileset/Tileset_Compressed_B_NoAnimation.png")

  chunks: [dynamic]TerrainChunk

  // engine.camera.target = { f32(max_chunks_per_line * 1280 * 4), f32(-max_chunks_per_line * 720 * 4) }
  // engine.camera.zoom = 0.04
  engine.camera.target = { f32(engine.game_state.resolution.x * 2), f32(engine.game_state.resolution.y * 2) }
  engine.camera.zoom = 0.75

  current_regen_pos: [2]int = { 0, 0 }
  regen:= true

  for !rl.WindowShouldClose() {
    deltaTime := rl.GetFrameTime()

    if rl.IsKeyPressed(rl.KeyboardKey.N) {
      noise_scale += rl.IsKeyDown(rl.KeyboardKey.LEFT_SHIFT) ? 0.005 : -0.005
    }

    if rl.IsKeyPressed(rl.KeyboardKey.R) {
      current_regen_pos = { 0, 0 }
      clear(&chunks)

      regen = true
    }

    if regen && current_regen_pos.y != max_chunks_per_line {
      start_y := current_regen_pos.y * 720
      start_x := current_regen_pos.x * 1280

      t: rl.RenderTexture = rl.LoadRenderTexture(1280 * 8, 720 * 8)

      rl.BeginTextureMode(t)
      rl.ClearBackground(rl.BLACK)
      terrain = perlin_noise.generate(1280, 720, noise_scale = noise_scale, scale = scale, start_x = start_x, start_y = start_y)
      perlin_noise.draw_terrain(&terrain, scale, tileset)
      rl.EndTextureMode()

      append(&chunks,  TerrainChunk { t, { current_regen_pos.x, current_regen_pos.y } })

      current_regen_pos.x += 1
      if current_regen_pos.x == max_chunks_per_line {
        current_regen_pos.x = 0
        current_regen_pos.y += 1
      }
    }


    if rl.IsKeyDown(rl.KeyboardKey.Q) do engine.camera.zoom += 1 * deltaTime
    if rl.IsKeyDown(rl.KeyboardKey.A) do engine.camera.zoom -= 1 * deltaTime

    if rl.IsKeyDown(rl.KeyboardKey.LEFT) do engine.camera.offset.x += 1000 * deltaTime
    if rl.IsKeyDown(rl.KeyboardKey.RIGHT) do engine.camera.offset.x -= 1000 * deltaTime
    if rl.IsKeyDown(rl.KeyboardKey.UP) do engine.camera.offset.y += 1000 * deltaTime
    if rl.IsKeyDown(rl.KeyboardKey.DOWN) do engine.camera.offset.y -= 1000 * deltaTime

    rl.BeginDrawing()
    rl.BeginMode2D(engine.camera)

  rl.ClearBackground(rl.BLACK)

  for &c in chunks {
  rl.DrawTexture(c.rt.texture, i32(c.position.x * 1280 * 8), i32(-c.position.y * 720 * 8), rl.WHITE)

  }

  // rl.DrawTexture(t.texture, 0, 0, rl.WHITE)
  // rl.DrawTexture(t2.texture, 1280 * 8, 0, rl.WHITE)
  // rl.DrawTexture(t5.texture, -1280 * 8, 0, rl.WHITE)
  // rl.DrawTexture(t3.texture, 0, -720 * 8, rl.WHITE)
  // rl.DrawTexture(t4.texture, 0, 720 * 8, rl.WHITE)

    rl.EndMode2D()
    rl.DrawText(rl.TextFormat("noise_scale: %f, scale: %d\n", noise_scale, scale, engine.camera), 20, 20, 20, rl.WHITE)
    rl.DrawFPS(0, 0)
    rl.EndDrawing()
  }


  // engine.scene_create(enums.SceneID.MAIN,  uses_camera = true)
  // engine.scene_create(enums.SceneID.PAUSE, uses_camera = false)
  // engine.scene_set_current(enums.SceneID.MAIN)
  //
  // engine.scene_overlay_create(enums.SceneID.MAIN, enums.OverlayID.INVENTORY, width_ratio = 0.5, height_ratio = 0.1)
  // engine.scene_overlay_create(enums.SceneID.MAIN, enums.OverlayID.CRAFT, width_ratio = 0.6, height_ratio = 0.6)
  //
  // engine.system_register(ui_system_update_camera_position,       { int(enums.SceneID.MAIN) })
  // engine.system_register(ui_system_animated_sprite_update,       { int(enums.SceneID.MAIN) })
  // engine.system_register(input_system_main,                      { int(enums.SceneID.MAIN) })
  // engine.system_register(input_system_player_movement,           { int(enums.SceneID.MAIN) }, recurrence_in_ms = 10)
  // engine.system_register(ui_system_text_box_update,              { int(enums.SceneID.MAIN) })
  // engine.system_register(bounding_box_system_collision_resolver, { int(enums.SceneID.MAIN) })
  // engine.system_register(ui_system_drawable_draw,                { int(enums.SceneID.MAIN) })
  // engine.system_register(bounding_box_system_draw,               { int(enums.SceneID.MAIN) })
  // engine.system_register(ui_system_text_box_draw,                { int(enums.SceneID.MAIN) })
  //
  // engine.system_overlay_register(overlay_system_draw,            { int(enums.SceneID.MAIN) })
  //
  // engine.system_register(pause_system_main)
  // engine.system_register(pause_system_toggle)
  //
  // engine.system_register(collectable_system_main)
  //
  // init_npc()
  // init_player()
  // init_terrain()
  //
  // engine.run()
  // engine.unload()
}
