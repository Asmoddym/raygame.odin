#+feature dynamic-literals

package macro

import "core:fmt"
import "core:time"
import "engine"
import "graphics"
import "enums"
import "ui"

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
  animated_sprite := engine.database_get_component(player, &table_animated_sprites)
  box := &engine.database_get_component(player, &table_bounding_boxs).box

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
}

update_camera_position :: proc() {
  box := engine.database_get_component(player, &table_bounding_boxs).box

  engine.camera.target = rl.Vector2 { f32(box.x), f32(box.y) }
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
  if rl.IsKeyPressed(rl.KeyboardKey.A) {
    text := engine.database_add_component(engine.database_create_entity(), &table_texts)
    text.text = "coucou c'est moi et je suis un texte animé oulala c'est rigolo !"
    text.duration = 10000
    text.size = 20
    text.instanciated_at = time.now()
    text.attached_to_box = &(engine.database_get_component(player, &table_bounding_boxs).box)

    text.animated = true
    text.ticks = 0
  }
}

draw_texts :: proc() {
  for &item in table_texts.items {
    box := item.attached_to_box

    if box != nil {
      position := rl.Vector2 { box.x + box.width, box.y }

      if item.animated {
        ui.draw_animated_text_box(item.text, item.size, position, item.ticks)
      } else {
        ui.draw_text_box(item.text, item.size, position)
      }
    }
  }
}

update_texts :: proc() {
  to_delete: [dynamic]int

  for &item in table_texts.items {
    time_diff := time.duration_milliseconds(time.diff(item.instanciated_at, time.now()))

    if item.animated && item.ticks != len(item.text) {
      // 20ms for each letter
      item.ticks = int(time_diff / 20)
    }

    if item.duration != -1 && time_diff > item.duration {
      append(&to_delete, item.entity_id)
    }
  }

  for id in to_delete {
    engine.database_destroy_component(id, &table_texts)
  }
}

pause_system :: proc() {
  @(static) selection:= 0

  if rl.IsKeyPressed(rl.KeyboardKey.UP) do selection = (selection + 1) % 2
  if rl.IsKeyPressed(rl.KeyboardKey.DOWN) do selection = selection == 0 ? 1 : selection - 1

  ui.draw_xy_centered_button_list(
    { "Toggle borderless window", "Exit" },
    font_size = 40,
    on_click = {
      proc() { engine.game_state.borderless_window = !engine.game_state.borderless_window },
      proc() { engine.game_state.closed = true },
    },
    selected = selection,
  )
}

player: int

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
  engine.database_add_component(npc, &table_bounding_boxs).box = rl.Rectangle { 100, 100, f32(sprite.texture.width), f32(sprite.texture.height) }
  text := engine.database_add_component(npc, &table_texts)
  text.text = "J'ai terriblement faim a l'aide :("
  text.size = 20
  text.duration = -1
  text.attached_to_box = &engine.database_get_component(npc, &table_bounding_boxs).box

  // Player
  player = engine.database_create_entity()
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
