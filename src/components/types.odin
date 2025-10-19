package components

import "../engine"
import "../graphics"
import "core:time"
import rl "vendor:raylib"

Component :: struct($T: typeid) {
  entity_id: int,

  metadata: T,
}

// Sprite

Component_Sprite :: struct {
  using base: Component(Metadata),

  texture: rl.Texture2D,
}

table_sprites: engine.Table(Component_Sprite)

// Controllable

Component_Controllable :: struct {
  using base: Component(Metadata),
}

table_controllables: engine.Table(Component_Controllable)

// AnimatedSprite

Component_AnimatedSprite :: struct {
  using base: Component(Metadata),

  states: map[int]graphics.Spritesheet,
  state: int,
  last_updated_at: time.Time,
}

table_animated_sprites: engine.Table(Component_AnimatedSprite)

// Movable

Component_Movable :: struct {
  using base: Component(Metadata),
}

table_movables: engine.Table(Component_Movable)

// BoundingBox

Component_BoundingBox :: struct {
  using base: Component(Metadata),

  box: rl.Rectangle,
}

table_bounding_boxes: engine.Table(Component_BoundingBox)

// Text

Component_TextBox :: struct {
  using base: Component(TextBoxMetadata),

  duration: f64,
  instanciated_at: time.Time,
  attached_to_box: ^rl.Rectangle,

  animated: bool,
  ticks: int,
}

table_text_boxes: engine.Table(Component_TextBox)
