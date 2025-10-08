#+feature dynamic-literals

package macro

import "core:fmt"
import "core:time"
import "engine"
import "graphics"
import "enums"

import rl "vendor:raylib"

draw_sprites :: proc() {
  for sprite in table_sprites.items {
    box := engine.database_get_component(sprite.entity_id, &table_bounding_boxs).box
    source := rl.Rectangle { 0, 0, box.width, box.height }
    dest := box

    rl.DrawTexturePro(sprite.texture, source, dest, rl.Vector2 { 0, 0 }, 0, rl.WHITE)
  }
}

draw_animated_sprites :: proc() {
  for sprite in table_animated_sprites.items {
    box := engine.database_get_component(sprite.entity_id, &table_bounding_boxs).box
    spritesheet := sprite.states[sprite.state]

    source := rl.Rectangle {
      f32(spritesheet.index * int(spritesheet.texture.height)),
      0,
      f32(spritesheet.texture.height),
      f32(spritesheet.texture.height),
    }
    dest := box

    rl.DrawTexturePro(spritesheet.texture, source, dest, rl.Vector2 { 0, 0 }, 0, rl.WHITE)
  }
}

move_controllable :: proc() {
  controllable := table_controllables.items[0]
  animated_sprite := engine.database_get_component(controllable.entity_id, &table_animated_sprites)
  box := &engine.database_get_component(controllable.entity_id, &table_bounding_boxs).box

  animated_sprite.state = int(enums.Direction.NONE)
  if rl.IsKeyDown(rl.KeyboardKey.LEFT) {
    box.x -= 3
    animated_sprite.state = int(enums.Direction.LEFT)
  }

  if rl.IsKeyDown(rl.KeyboardKey.RIGHT) {
    box.x += 3
    animated_sprite.state = int(enums.Direction.RIGHT)
  }

  if rl.IsKeyDown(rl.KeyboardKey.UP) {
    box.y -= 3
    animated_sprite.state = int(enums.Direction.UP)
  }

  if rl.IsKeyDown(rl.KeyboardKey.DOWN) {
    box.y += 3
    animated_sprite.state = int(enums.Direction.DOWN)
  }

  graphics.camera.target = rl.Vector2 { f32(box.x), f32(box.y) }
}

update_animated_sprites :: proc() {
  for &item in table_animated_sprites.items {
    current_state := &item.states[item.state]

    if time.duration_milliseconds(time.diff(item.last_updated_at, time.now())) > f64(1000 / current_state.tiles) {
      item.last_updated_at = time.now()
      current_state.index = (current_state.index + 1) % current_state.tiles
    }
  }
}

handle_inputs :: proc() {
}


main :: proc() {
  engine.init()

  engine.systems_register(draw_sprites)
  engine.systems_register(draw_animated_sprites)
  engine.systems_register(update_animated_sprites)
  engine.systems_register(handle_inputs)
  engine.systems_register(move_controllable, recurrence_in_ms = 10)
  engine.systems_register(collision_system)

  // NPC
  npc := engine.database_create_entity()
  sprite := engine.database_add_component(npc, &table_sprites)
  sprite.texture = rl.LoadTexture("wabbit_alpha.png")
  engine.database_add_component(npc, &table_bounding_boxs).box = rl.Rectangle { 100, 100, f32(sprite.texture.width), f32(sprite.texture.height) }

  // Player
  player := engine.database_create_entity()
  engine.database_add_component(player, &table_controllables)
  engine.database_add_component(player, &table_movables)
  engine.database_add_component(player, &table_bounding_boxs).box = rl.Rectangle { 300, 300, 64.0, 64.0 }
  player_animated_sprite := engine.database_add_component(player, &table_animated_sprites)

  graphics.animated_sprite_init(player_animated_sprite, {
    int(enums.Direction.NONE) = "idle.png",
    int(enums.Direction.UP) = "up.png",
    int(enums.Direction.DOWN) = "down.png",
    int(enums.Direction.LEFT) = "left.png",
    int(enums.Direction.RIGHT) = "right.png",
  })

  engine.run()
}
