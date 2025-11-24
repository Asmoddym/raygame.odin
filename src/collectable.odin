package macro

import "engine"
import "globals"
import rl "vendor:raylib"


Component_CollectableMetadata :: struct {
  pickup_text_box_id: int,
  interaction_text_box_id: int,

  bounding_box: ^Component_BoundingBox,
  bounding_box_layer: int,
}

// Collectable component.
// keep_interaction_alive is dynamically set to true to force the interaction text to stay after duration
Component_Collectable :: struct {
  using base: engine.Component(Component_CollectableMetadata),

  interaction_text: string,
  keep_interaction_alive: bool,
}

// Table
table_collectables: engine.Table(Component_Collectable)


// WIP: Backpack component. Will hold inventory for entities having one, not necessarily the player.

Component_Backpack :: struct {
  using base: engine.Component(engine.Metadata),

  has_npc: bool,
}

table_backpacks: engine.Table(Component_Backpack)



//
// SYSTEMS
//



collectable_system_main :: proc() {
  player_box := engine.database_get_component(globals.player_id, &table_bounding_boxes[globals.PLAYER_LAYER])
  player_rect := player_box.box

  for &collectable in table_collectables.items {
    if collectable.entity_id == globals.player_id do continue

    entity_id := collectable.entity_id
    bounding_box := collectable.metadata.bounding_box

    if rl.CheckCollisionRecs(bounding_box.box, player_rect) {
      if collectable.metadata.pickup_text_box_id == 0 {
        ui_text_box_draw(
          "(E) pickup",
          font_size = 20,
          attached_to_bounding_box = player_box,
          owner_id = &collectable.metadata.pickup_text_box_id,
        )

        // These two conditions are nested to prevent the interaction text recreation if you just stay on the item
        if collectable.metadata.interaction_text_box_id == 0 {
          ui_animated_text_box_draw(
            collectable.interaction_text,
            font_size = 20,
            duration = 2000,
            attached_to_bounding_box = bounding_box,
            owner_id = &collectable.metadata.interaction_text_box_id,
            keep_alive_until_false = &collectable.keep_interaction_alive,
          )
        }
      } else {
        if collectable.metadata.interaction_text_box_id != 0 do collectable.keep_interaction_alive = true
      }

      if rl.IsKeyPressed(rl.KeyboardKey.E) {
        engine.database_destroy_component(entity_id, &table_collectables)
        if collectable.metadata.pickup_text_box_id != 0 do ui_text_box_delete(collectable.metadata.pickup_text_box_id)
        if collectable.metadata.interaction_text_box_id != 0 do ui_text_box_delete(collectable.metadata.interaction_text_box_id)

        engine.database_destroy_component(entity_id, &table_bounding_boxes[collectable.metadata.bounding_box_layer])
        engine.database_destroy_component(entity_id, &table_animated_sprites[collectable.metadata.bounding_box_layer])

        engine.database_get_component(globals.player_id, &table_backpacks).has_npc = true
      }
    } else {
      collectable.keep_interaction_alive = false
      if collectable.metadata.pickup_text_box_id != 0 {
        ui_text_box_delete(collectable.metadata.pickup_text_box_id)
        collectable.metadata.pickup_text_box_id = 0
      }
    }
  }
}

