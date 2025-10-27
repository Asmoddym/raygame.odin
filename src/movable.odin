package macro

import "engine"

// Movable

Component_Movable :: struct {
  using base: engine.Component(engine.Metadata),
}

table_movables: engine.Table(Component_Movable)
