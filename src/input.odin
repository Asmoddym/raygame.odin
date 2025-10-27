package macro

import rl "vendor:raylib"
import "engine"
import "globals"

handle_inputs :: proc() {
  if rl.IsKeyPressed(rl.KeyboardKey.A) {
    text := engine.database_add_component(globals.player, &table_text_boxes)

    init_animated_text_box(text,
      "coucou c'est moi et je suis un texte animé oulala c'est rigolo !",
      font_size = 20,
      attached_to_entity_id = globals.player,
      duration = 10000,
    )
  }
}

