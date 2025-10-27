package macro

import "engine"
import "enums"
import rl "vendor:raylib"
import "globals"

// Controllable

Component_Controllable :: struct {
  using base: engine.Component(engine.Metadata),
}

table_controllables: engine.Table(Component_Controllable)

move_controllable :: proc() {
  animated_sprite := engine.database_get_component(globals.player, &table_animated_sprites)
  box := &engine.database_get_component(globals.player, &table_bounding_boxes).box

  animated_sprite.state = int(enums.Direction.NONE)
  if rl.IsKeyDown(rl.KeyboardKey.LEFT) {
    box.x -= 3
    animated_sprite.state = int(enums.Direction.LEFT)
  }

  if rl.IsKeyDown(rl.KeyboardKey.RIGHT) {
    box.x += 3
    animated_sprite.state = int(enums.Direction.RIGHT)
  }

  if rl.IsKeyDown(rl.KeyboardKey.UP) {
    box.y -= 3
    animated_sprite.state = int(enums.Direction.UP)
  }

  if rl.IsKeyDown(rl.KeyboardKey.DOWN) {
    box.y += 3
    animated_sprite.state = int(enums.Direction.DOWN)
  }
}

