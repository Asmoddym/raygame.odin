package macro

import "engine"
import "globals"
import "enums"
import rl "vendor:raylib"



//
// SYSTEMS
//



// Input handling for default runtime systems.
//
// For now, overlay inputs are handled in their respective systems
input_system_main :: proc() {
  if engine.game_state.current_scene.id == 0 do input_subsystem_default()
}



//
// PRIVATE
//



// Default input system
@(private="file")
input_subsystem_default :: proc() {
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

  input_subsystem_handle_player_movement(bbox)
}

// Handle player movement with animated sprite state
@(private="file")
input_subsystem_handle_player_movement :: proc(bbox: ^Component_BoundingBox) {
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

