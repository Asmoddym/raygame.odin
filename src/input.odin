package macro

import "engine"
import "globals"
import "enums"
import rl "vendor:raylib"



//
// SYSTEMS
//



// Input handling for default runtime systems.
input_system_main :: proc() {
  bbox := engine.database_get_component(globals.player_id, &table_bounding_boxes[globals.PLAYER_LAYER])

  // Text box test stuff
  if rl.IsKeyPressed(rl.KeyboardKey.A) {
    ui_animated_text_box_draw(
      "coucou c'est moi et je suis un texte animé oulala c'est rigolo !",
      font_size = 20,
      duration = 2000,
      attached_to_bounding_box = bbox,
    )
  }
}

// Handle player movement with animated sprite state
input_system_player_movement :: proc() {
  bbox            := engine.database_get_component(globals.player_id, &table_bounding_boxes[globals.PLAYER_LAYER])
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

