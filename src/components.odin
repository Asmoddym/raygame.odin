package macro

import "engine"
import "graphics"
import "core:time"
import rl "vendor:raylib"

Component :: struct {
  id: int,
  eid: int,
}

// Texture

Component_Texture :: struct {
  using base: Component,

  texture: rl.Texture2D,
}

table_textures: engine.Table(Component_Texture)

// Position

Component_Position :: struct {
  using base: Component,

  x: int,
  y: int,
}

table_positions: engine.Table(Component_Position)

// Dimensions

Component_Dimensions :: struct {
  using base: Component,

  width: int,
  height: int,
}

table_dimensions: engine.Table(Component_Dimensions)

// Controllable

Component_Controllable :: struct {
  using base: Component,
}

table_controllables: engine.Table(Component_Controllable)

// Sprite

Component_Sprite :: struct {
  using base: Component,

  states: map[int]graphics.Spritesheet,
  state: int,
  last_updated_at: time.Time,
}

table_sprites: engine.Table(Component_Sprite)

