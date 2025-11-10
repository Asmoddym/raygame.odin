package macro

import "engine"
import "globals"
import rl "vendor:raylib"



//
// SYSTEMS
//



// Input handling (only test stuff for now)
input_system_main :: proc() {
  if rl.IsKeyPressed(rl.KeyboardKey.A) {
    box := engine.database_get_component(globals.player_id, &table_bounding_boxes[globals.PLAYER_LAYER])

    ui_animated_text_box_draw(
      "coucou c'est moi et je suis un texte animé oulala c'est rigolo !",
      font_size = 20,
      duration = 2000,
      attached_to_bounding_box = box,
    )
  }
}

