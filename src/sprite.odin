package macro 

import "core:strings"
import "core:time"
import "engine"
import rl "vendor:raylib"


// COMPONENTS DEFINITION


// TODO: Make this a metadata
Spritesheet :: struct {
  texture: rl.Texture2D,
  index: int,
  tiles: int,
}

Component_Sprite :: struct {
  using base: engine.Component(engine.Metadata),

  texture: rl.Texture2D,
}

Component_AnimatedSprite :: struct {
  using base: engine.Component(engine.Metadata),

  states: map[int]Spritesheet,
  state: int,
  last_updated_at: time.Time,
}

table_sprites: engine.Table(Component_Sprite)
table_animated_sprites: engine.Table(Component_AnimatedSprite)


// ANIMATED SPRITE


// Init an animated sprite from a sprite address and the sprites configuration defined as { ENUM/int = "file.png" }
ui_animated_sprite_init :: proc(self: ^$Component_AnimatedSprite, cfg: map[int]string) {
  self.last_updated_at = time.now()

  for idx, path in cfg {
    // Normally this is OK as Texture2D is a simple struct
    texture := rl.LoadTexture(strings.unsafe_string_to_cstring(path))

    self.states[idx] = Spritesheet { texture, 0, int(texture.width / texture.height) }
  }
}



//
// SYSTEMS
//



// Draw simple sprites
ui_system_sprite_draw :: proc() {
  for sprite in table_sprites.items {
    box := engine.database_get_component(sprite.entity_id, &table_bounding_boxes).box
    source := rl.Rectangle { 0, 0, f32(sprite.texture.width), f32(sprite.texture.height) }
    dest := box

    rl.DrawTexturePro(sprite.texture, source, dest, rl.Vector2 { 0, 0 }, 0, rl.WHITE)
  }
}

// Update animated sprites current state
ui_system_animated_sprite_update :: proc() {
  for &item in table_animated_sprites.items {
    current_state := &item.states[item.state]

    if time.duration_milliseconds(time.diff(item.last_updated_at, time.now())) > f64(1000 / current_state.tiles) {
      item.last_updated_at = time.now()
      current_state.index = (current_state.index + 1) % current_state.tiles
    }
  }
}

// Draw animated sprites
ui_system_animated_sprite_draw :: proc() {
  for sprite in table_animated_sprites.items {
    box := engine.database_get_component(sprite.entity_id, &table_bounding_boxes).box
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
