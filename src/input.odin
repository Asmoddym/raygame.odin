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
  bbox            := engine.database_get_component(globals.player_id, &bounding_box.tables[globals.PLAYER_LAYER])
  animated_sprite := engine.database_get_component(globals.player_id, &table_animated_sprites[globals.PLAYER_LAYER])

  animated_sprite.state = int(enums.Direction.NONE)

  if rl.IsKeyDown(rl.KeyboardKey.LEFT) {
    bbox.box.x -= 3
    animated_sprite.state = int(enums.Direction.LEFT)
  }

  if rl.IsKeyDown(rl.KeyboardKey.RIGHT) {
    bbox.box.x += 3
    animated_sprite.state = int(enums.Direction.RIGHT)
  }

  if rl.IsKeyDown(rl.KeyboardKey.UP) {
    bbox.box.y -= 3
    animated_sprite.state = int(enums.Direction.UP)
  }

  if rl.IsKeyDown(rl.KeyboardKey.DOWN) {
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
