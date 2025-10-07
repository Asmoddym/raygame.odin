package graphics

import "core:strings"
import "core:time"
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
