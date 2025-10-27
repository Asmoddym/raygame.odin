package components

import "core:time"
import "core:strings"
import "../engine"
import rl "vendor:raylib"

Spritesheet :: struct {
  texture: rl.Texture2D,
  index: int,
  tiles: int,
}

animated_sprite_init :: proc(self: ^$Type, cfg: map[int]string) {
  self.last_updated_at = time.now()

  for idx, path in cfg {
    // Normally this is OK as Texture2D is a simple struct
    texture := rl.LoadTexture(strings.unsafe_string_to_cstring(path))

    self.states[idx] = Spritesheet { texture, 0, int(texture.width / texture.height) }
  }
}
// Sprite

Component_Sprite :: struct {
  using base: engine.Component(engine.Metadata),

  texture: rl.Texture2D,
}

table_sprites: engine.Table(Component_Sprite)

// AnimatedSprite

Component_AnimatedSprite :: struct {
  using base: engine.Component(engine.Metadata),

  states: map[int]Spritesheet,
  state: int,
  last_updated_at: time.Time,
}

table_animated_sprites: engine.Table(Component_AnimatedSprite)

