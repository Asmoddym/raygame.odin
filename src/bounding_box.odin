package macro

import "engine"
import rl "vendor:raylib"

// BoundingBox

Component_BoundingBox :: struct {
  using base: engine.Component(engine.Metadata),

  box: rl.Rectangle,
}

table_bounding_boxes: engine.Table(Component_BoundingBox)

