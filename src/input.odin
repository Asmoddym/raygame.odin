package macro

import "engine"
import "globals"
import "bounding_box"
import "enums"
import rl "vendor:raylib"



//
// SYSTEMS
//



// Handle player movement with animated sprite state
input_system_player_movement :: proc() {
  bbox            := engine.database_get_component(globals.player_id, &bounding_box.layers[globals.PLAYER_LAYER_ID])
  animated_sprite := engine.database_get_component(globals.player_id, &table_animated_sprites[globals.PLAYER_LAYER_ID])

  animated_sprite.state = int(enums.Direction.NONE)

  if rl.IsKeyDown(rl.KeyboardKey.J) {
    bbox.box.x -= 3
    animated_sprite.state = int(enums.Direction.LEFT)
  }

  if rl.IsKeyDown(rl.KeyboardKey.L) {
    bbox.box.x += 3
    animated_sprite.state = int(enums.Direction.RIGHT)
  }

  if rl.IsKeyDown(rl.KeyboardKey.I) {
    bbox.box.y -= 3
    animated_sprite.state = int(enums.Direction.UP)
  }

  if rl.IsKeyDown(rl.KeyboardKey.K) {
    bbox.box.y += 3
    animated_sprite.state = int(enums.Direction.DOWN)
  }
}



//
// PRIVATE
//



// CONSTANTS


// Zoom interval
@(private="file")
ZOOM_INTERVAL: [2]f32 = { 0.3, 3 }
