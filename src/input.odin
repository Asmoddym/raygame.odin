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
    text := engine.database_add_component(globals.player_id, &table_text_boxes)
    box := engine.database_get_component(globals.player_id, &table_bounding_boxes[0])

    ui_animated_text_box_init(text,
      "coucou c'est moi et je suis un texte animé oulala c'est rigolo !",
      font_size = 20,
      duration = 10000,
      attached_to_bounding_box = box,
    )
  }
}

