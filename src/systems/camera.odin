package systems

import "../engine"
import "../components"
import "../globals"

import rl "vendor:raylib"

update_camera_position :: proc() {
  box := engine.database_get_component(globals.player, &components.table_bounding_boxes).box

  engine.camera.target = rl.Vector2 { f32(box.x), f32(box.y) }
}
