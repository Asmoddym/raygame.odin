package macro

import "engine"
import "graphics"
import "core:time"
import rl "vendor:raylib"

Component :: struct {
  entity_id: int,
}

// Sprite

Component_Sprite :: struct {
  using base: Component,

  texture: rl.Texture2D,
}

table_sprites: engine.Table(Component_Sprite)

// Controllable

Component_Controllable :: struct {
  using base: Component,
}

table_controllables: engine.Table(Component_Controllable)

// AnimatedSprite

Component_AnimatedSprite :: struct {
  using base: Component,

  states: map[int]graphics.Spritesheet,
  state: int,
  last_updated_at: time.Time,
}

table_animated_sprites: engine.Table(Component_AnimatedSprite)

// Movable

Component_Movable :: struct {
  using base: Component,
}

table_movables: engine.Table(Component_Movable)

// BoundingBox

Component_BoundingBox :: struct {
  using base: Component,

  box: rl.Rectangle,
}

table_bounding_boxs: engine.Table(Component_BoundingBox)

// Text

Component_Text :: struct {
  using base: Component,

  text: string,
  size: i32,
  duration: f64,
  instanciated_at: time.Time,
  attached_to_box: ^rl.Rectangle,

  animated: bool,
  ticks: int,
}

table_texts: engine.Table(Component_Text)
