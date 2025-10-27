package systems

import "../engine"
import rl "vendor:raylib"
import "../enums"
import "../components"
import "../globals"

move_controllable :: proc() {
  animated_sprite := engine.database_get_component(globals.player, &components.table_animated_sprites)
  box := &engine.database_get_component(globals.player, &components.table_bounding_boxes).box

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
