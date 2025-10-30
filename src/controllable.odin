package macro

import "engine"
import "enums"
import "globals"
import rl "vendor:raylib"


// COMPONENTS DEFINITION


Component_Controllable :: struct {
  using base: engine.Component(engine.Metadata),
}

table_controllables: engine.Table(Component_Controllable)



//
// SYSTEMS
//



// Controllable handling from inputs
controllable_system_handle_inputs :: proc() {
  animated_sprite := engine.database_get_component(globals.player_id, &table_animated_sprites[0])
  box := &engine.database_get_component(globals.player_id, &table_bounding_boxes[0]).box

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

