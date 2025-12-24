#+feature dynamic-literals

package macro

import "core:os"
import "core:fmt"
import "engine"
import "enums"
import "globals"
import rl "vendor:raylib"
import "lib/perlin_noise"

// BOX_SIZE: f32 = 64
//
// init_npc :: proc() {
//   npc := engine.database_create_entity()
//   bounding_box := engine.database_add_component(npc, &table_bounding_boxes[1])
//   bounding_box.box = rl.Rectangle { 100, 100, BOX_SIZE, BOX_SIZE }
//   bounding_box.movable = false
//   bounding_box.collidable = true
//   bounding_box.layer = 1
//
//   ui_animated_sprite_init(engine.database_add_component(npc, &table_animated_sprites[1]), {
//     int(enums.Direction.NONE) = "idle.png",
//     int(enums.Direction.UP) = "up.png",
//     int(enums.Direction.DOWN) = "down.png",
//     int(enums.Direction.LEFT) = "left.png",
//     int(enums.Direction.RIGHT) = "right.png",
//   }, enums.Direction.NONE)
//
//   collectable := engine.database_add_component(npc, &table_collectables)
//   collectable.interaction_text = "seed je suis gentil"
//   collectable.metadata.pickup_text_box_id = 0
//   collectable.metadata.interaction_text_box_id = 0
//   collectable.metadata.bounding_box = bounding_box
//   collectable.metadata.keep_interaction_alive = false
//
//   engine.database_add_component(npc, &table_backpacks).items = { .FLOWER }
// }
//
// init_player :: proc() {
//   globals.player_id = engine.database_create_entity()
//   bounding_box := engine.database_add_component(globals.player_id, &table_bounding_boxes[globals.PLAYER_LAYER])
//   bounding_box.box = rl.Rectangle { 300, 300, BOX_SIZE, BOX_SIZE }
//   bounding_box.movable = true
//   bounding_box.collidable = true
//   bounding_box.layer = globals.PLAYER_LAYER
//   player_animated_sprite := engine.database_add_component(globals.player_id, &table_animated_sprites[globals.PLAYER_LAYER])
//   engine.database_add_component(globals.player_id, &table_backpacks).max_items = 5
//
//   ui_animated_sprite_init(player_animated_sprite, {
//     int(enums.Direction.NONE) = "idle.png",
//     int(enums.Direction.UP) = "up.png",
//     int(enums.Direction.DOWN) = "down.png",
//     int(enums.Direction.LEFT) = "left.png",
//     int(enums.Direction.RIGHT) = "right.png",
//   }, enums.Direction.NONE)
// }
//
// init_terrain :: proc() {
//   tree_trunk_1 := engine.database_create_entity()
//   engine.database_add_component(tree_trunk_1, &table_sprites[globals.PLAYER_LAYER]).texture = engine.assets_find_or_create(rl.Texture2D, "tree_trunk_1.png")
//   tree_trunk_1_bb := engine.database_add_component(tree_trunk_1, &table_bounding_boxes[globals.PLAYER_LAYER])
//   tree_trunk_1_bb.box = rl.Rectangle { 500, 500, BOX_SIZE, BOX_SIZE }
//   tree_trunk_1_bb.movable = true
//   tree_trunk_1_bb.collidable = true
//   tree_trunk_1_bb.layer = globals.PLAYER_LAYER
//
//   tree_trunk_2 := engine.database_create_entity()
//   engine.database_add_component(tree_trunk_2, &table_sprites[globals.PLAYER_LAYER + 1]).texture = engine.assets_find_or_create(rl.Texture2D, "tree_trunk_2.png")
//   tree_trunk_2_bb := engine.database_add_component(tree_trunk_2, &table_bounding_boxes[globals.PLAYER_LAYER + 1])
//   tree_trunk_2_bb.box = rl.Rectangle { 500, 500 - BOX_SIZE, BOX_SIZE, BOX_SIZE }
//   tree_trunk_2_bb.movable = false
//   tree_trunk_2_bb.collidable = false
//   tree_trunk_2_bb.layer = globals.PLAYER_LAYER + 1
//
//   tree_leaves := engine.database_create_entity()
//   engine.database_add_component(tree_leaves, &table_sprites[globals.PLAYER_LAYER + 1]).texture = engine.assets_find_or_create(rl.Texture2D, "tree_leaves.png")
//   tree_leaves_bb := engine.database_add_component(tree_leaves, &table_bounding_boxes[globals.PLAYER_LAYER + 1])
//   tree_leaves_bb.box = rl.Rectangle { 500 - (BOX_SIZE * 1) / 2, 500 - BOX_SIZE * 2 - BOX_SIZE, BOX_SIZE * 2, BOX_SIZE * 2}
//   tree_leaves_bb.movable = false
//   tree_leaves_bb.collidable = false
//   tree_leaves_bb.layer = globals.PLAYER_LAYER + 1
//
//
//   // Additional
//   root := engine.database_create_entity()
//   engine.database_add_component(root, &table_sprites[globals.PLAYER_LAYER]).texture = engine.assets_find_or_create(rl.Texture2D, "tree_trunk_1.png")
//   root_bb := engine.database_add_component(root, &table_bounding_boxes[globals.PLAYER_LAYER])
//   root_bb.box = rl.Rectangle { 650, 500, BOX_SIZE, BOX_SIZE }
//   root_bb.movable = false
//   root_bb.collidable = true
//   root_bb.layer = globals.PLAYER_LAYER
// }

import "terrain"
import rand "core:math/rand"

max_chunks_per_line := 10

main :: proc() {
  engine.init()

  tileset := engine.assets_find_or_create(rl.Texture2D, "tileset/Tileset_Compressed_B_NoAnimation.png")

  current_regen_pos : [2]int = { 0, 0 }
  regen             := false
  prepare_for_regen := true
  terrain_handle    := terrain.initialize_handle(200, 200, tileset)

  // engine.camera.target = { f32(max_chunks_per_line * 1280 * 4), f32(-max_chunks_per_line * 720 * 4) }
  // engine.camera.zoom = 0.04
  // engine.camera.target = { f32(terrain_handle.chunk_size.x * max_chunks_per_line / 2) * f32(terrain_handle.tile_size), f32(terrain_handle.chunk_size.y * max_chunks_per_line * max_chunks_per_line / 2) }
  engine.camera.zoom = 0.1
  engine.camera.target = { f32(engine.game_state.resolution.x * 2), f32(engine.game_state.resolution.y * 2) }

  @(static) seed: u64 = 16

  for !rl.WindowShouldClose() {
    deltaTime := rl.GetFrameTime()


    if rl.IsKeyPressed(rl.KeyboardKey.D) {
      terrain.debug_draw_mode += 1
      prepare_for_regen = true
    }

    if rl.IsKeyPressed(rl.KeyboardKey.R) {
      prepare_for_regen = true

      seed += 1
    }

    if prepare_for_regen {
      current_regen_pos = { 0, 0 }
      regen = true
      prepare_for_regen = false

      for &c in terrain_handle.chunks {
        rl.UnloadRenderTexture(c.render_texture)
        for &line in c.terrain {
          delete(line)
        }
        delete(c.terrain)
      }
      delete(terrain_handle.chunks)
      terrain_handle.chunks = {}

      rand.reset(seed)
      perlin_noise.repermutate(&terrain_handle.biome_noise_handle)
      perlin_noise.repermutate(&terrain_handle.default_noise_handle)
    }

    if regen && current_regen_pos.y != max_chunks_per_line {
      terrain.generate_chunk(&terrain_handle, current_regen_pos.x, current_regen_pos.y)

      current_regen_pos.x += 1
      if current_regen_pos.x == max_chunks_per_line {
        current_regen_pos.x = 0
        current_regen_pos.y += 1
      }
    }

    if rl.IsKeyDown(rl.KeyboardKey.Q) do engine.camera.zoom += 1 * deltaTime
    if rl.IsKeyDown(rl.KeyboardKey.A) do engine.camera.zoom -= 1 * deltaTime

    if engine.camera.zoom < 0 do engine.camera.zoom = 0.01

    if rl.IsKeyDown(rl.KeyboardKey.LEFT) do engine.camera.target.x -= 1000 * deltaTime * 1 / engine.camera.zoom
    if rl.IsKeyDown(rl.KeyboardKey.RIGHT) do engine.camera.target.x += 1000 * deltaTime* 1 / engine.camera.zoom
    if rl.IsKeyDown(rl.KeyboardKey.UP) do engine.camera.target.y -= 1000 * deltaTime* 1 / engine.camera.zoom
    if rl.IsKeyDown(rl.KeyboardKey.DOWN) do engine.camera.target.y += 1000 * deltaTime* 1 / engine.camera.zoom

    rl.BeginDrawing()
    rl.BeginMode2D(engine.camera)

    rl.ClearBackground(rl.BLACK)

    for &c in terrain_handle.chunks {
      // Using this method to invert the texture as that's the way Raylib works
      rl.DrawTextureRec(
        c.render_texture.texture,
        rl.Rectangle {
          0, 0,
          f32(terrain_handle.chunk_size.x * int(terrain_handle.displayed_tile_size)),
          -f32(terrain_handle.chunk_size.y * int(terrain_handle.displayed_tile_size)) },
        rl.Vector2 {
          f32(c.position.x * terrain_handle.chunk_size.x) * f32(terrain_handle.displayed_tile_size),
          f32(c.position.y * terrain_handle.chunk_size.y) * f32(terrain_handle.displayed_tile_size),
        },
        rl.WHITE,
      )
  }

    rl.EndMode2D()
    rl.DrawText(rl.TextFormat("> ", engine.camera, seed), 20, 20, 20, rl.WHITE)
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
