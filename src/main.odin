#+feature dynamic-literals

package macro

import "core:time"
import "engine"
import "graphics"
import "enums"
import "engine/error"

import rl "vendor:raylib"

draw_textures :: proc() {
  for t in table_textures.items {
    position := engine.database_get_component(t.eid, &table_positions, "position for draw")
    dimensions := engine.database_get_component(t.eid, &table_dimensions, "dimensions for draw", error_level = error.Level.NONE)

    source := rl.Rectangle {
      0,
      0,
      dimensions != nil ? f32(dimensions.width) : f32(t.texture.width),
      dimensions != nil ? f32(dimensions.height) : f32(t.texture.height),
    }

    dest := rl.Rectangle {
      f32(position.x),
      f32(position.y),
      dimensions != nil ? f32(dimensions.width) : f32(t.texture.width),
      dimensions != nil ? f32(dimensions.height) : f32(t.texture.height),
    }

    rl.DrawTexturePro(t.texture, source, dest, rl.Vector2 { 0, 0 }, 0, rl.WHITE)
  }
}

draw_sprites :: proc() {
  for sprite in table_sprites.items {
    position := engine.database_get_component(sprite.eid, &table_positions)
    dimensions := engine.database_get_component(sprite.eid, &table_dimensions, error_level = error.Level.WARN)
    spritesheet := sprite.states[sprite.state]

    source := rl.Rectangle {
      f32(spritesheet.index * int(spritesheet.texture.height)),
      0,
      f32(spritesheet.texture.height),
      f32(spritesheet.texture.height),
    }

    dest := rl.Rectangle {
      f32(position.x),
      f32(position.y),
      dimensions != nil ? f32(dimensions.width) : f32(spritesheet.texture.width),
      dimensions != nil ? f32(dimensions.height) : f32(spritesheet.texture.height),
    }

    rl.DrawTexturePro(spritesheet.texture, source, dest, rl.Vector2 { 0, 0 }, 0, rl.WHITE)
  }
}

move_controllable :: proc() {
  controllable := table_controllables.items[0]
  position := engine.database_get_component(controllable.eid, &table_positions)
  sprite := engine.database_get_component(controllable.eid, &table_sprites)

  sprite.state = int(enums.Direction.NONE)
  if rl.IsKeyDown(rl.KeyboardKey.LEFT) {
    position.x -= 3
    sprite.state = int(enums.Direction.LEFT)
  }

  if rl.IsKeyDown(rl.KeyboardKey.RIGHT) {
    position.x += 3
    sprite.state = int(enums.Direction.RIGHT)
  }

  if rl.IsKeyDown(rl.KeyboardKey.UP) {
    position.y -= 3
    sprite.state = int(enums.Direction.UP)
  }

  if rl.IsKeyDown(rl.KeyboardKey.DOWN) {
    position.y += 3
    sprite.state = int(enums.Direction.DOWN)
  }

  graphics.camera.target = rl.Vector2 { f32(position.x), f32(position.y) }
}

update_sprites :: proc() {
  for &sprite in table_sprites.items {
    current_state := &sprite.states[sprite.state]

    if time.duration_milliseconds(time.diff(sprite.last_updated_at, time.now())) > f64(1000 / current_state.tiles) {
      sprite.last_updated_at = time.now()
      current_state.index = (current_state.index + 1) % current_state.tiles
    }
  }
}

main :: proc() {
  engine.init()
  engine.database_init_table(&table_textures)

  engine.systems_register(draw_textures)
  engine.systems_register(draw_sprites)

  engine.systems_register(move_controllable, 10)
  engine.systems_register(update_sprites)

  // NPC
  npc := engine.database_create_entity()
  engine.database_add_component(npc, &table_textures).texture = rl.LoadTexture("wabbit_alpha.png")

  npc_position := engine.database_add_component(npc, &table_positions)
  npc_position.x = 100
  npc_position.y = 100

  // Player
  player := engine.database_create_entity()
  engine.database_add_component(player, &table_controllables)
  player_sprite := engine.database_add_component(player, &table_sprites)

  graphics.sprite_init(player_sprite, 
    {
      int(enums.Direction.NONE) = "idle.png",
      int(enums.Direction.UP) = "up.png",
      int(enums.Direction.DOWN) = "down.png",
      int(enums.Direction.LEFT) = "left.png",
      int(enums.Direction.RIGHT) = "right.png",
    })

  player_position := engine.database_add_component(player, &table_positions)
  player_position.x = 300
  player_position.y = 300

  player_dimensions := engine.database_add_component(player, &table_dimensions)
  player_dimensions.width = 64
  player_dimensions.height = 64

  engine.run()
}
