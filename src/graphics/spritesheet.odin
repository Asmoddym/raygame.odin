package graphics

import "core:fmt"
import "core:strings"
import "core:time"
import rl "vendor:raylib"

Spritesheet :: struct {
  texture: rl.Texture2D,
  index: int,
  tiles: int,
}

spritesheet_init :: proc(sheet: ^Spritesheet, texture_path: string) {
  fmt.println("coucou")
  sheet.texture = rl.LoadTexture(strings.unsafe_string_to_cstring(texture_path))
  fmt.println("coucou")
  // sheet.index = 0
  // fmt.println("coucou")
  // fmt.println("coucou")
}

sprite_init :: proc(sprite: ^$Type, cfg: map[int]string) {
  sprite.last_updated_at = time.now()

  for idx, path in cfg {
    sprite.states[idx] = Spritesheet { rl.LoadTexture(strings.unsafe_string_to_cstring(path)), 0, 0 }
    state := &sprite.states[idx]

    state.index = 2
    state.tiles = int(sprite.states[idx].texture.width / sprite.states[idx].texture.height)
    fmt.println(">> ", state.tiles)
  }
}
