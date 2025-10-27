package components

import "../engine"
import rl "vendor:raylib"

// Controllable

Component_Controllable :: struct {
  using base: engine.Component(engine.Metadata),
}

table_controllables: engine.Table(Component_Controllable)

// Movable

Component_Movable :: struct {
  using base: engine.Component(engine.Metadata),
}

table_movables: engine.Table(Component_Movable)

// BoundingBox

Component_BoundingBox :: struct {
  using base: engine.Component(engine.Metadata),

  box: rl.Rectangle,
}

table_bounding_boxes: engine.Table(Component_BoundingBox)

