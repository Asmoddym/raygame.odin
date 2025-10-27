package systems

import rl "vendor:raylib"
import "../components"
import "core:time"
import "../engine"

draw_sprites :: proc() {
  for sprite in components.table_sprites.items {
    box := engine.database_get_component(sprite.entity_id, &components.table_bounding_boxes).box
    source := rl.Rectangle { 0, 0, box.width, box.height }
    dest := box

    rl.DrawTexturePro(sprite.texture, source, dest, rl.Vector2 { 0, 0 }, 0, rl.WHITE)
  }
}

draw_animated_sprites :: proc() {
  for sprite in components.table_animated_sprites.items {
    box := engine.database_get_component(sprite.entity_id, &components.table_bounding_boxes).box
    spritesheet := sprite.states[sprite.state]

    source := rl.Rectangle {
      f32(spritesheet.index * int(spritesheet.texture.height)),
      0,
      f32(spritesheet.texture.height),
      f32(spritesheet.texture.height),
    }
    dest := box

    rl.DrawTexturePro(spritesheet.texture, source, dest, rl.Vector2 { 0, 0 }, 0, rl.WHITE)
  }
}

update_animated_sprites :: proc() {
  for &item in components.table_animated_sprites.items {
    current_state := &item.states[item.state]

    if time.duration_milliseconds(time.diff(item.last_updated_at, time.now())) > f64(1000 / current_state.tiles) {
      item.last_updated_at = time.now()
      current_state.index = (current_state.index + 1) % current_state.tiles
    }
  }
}
