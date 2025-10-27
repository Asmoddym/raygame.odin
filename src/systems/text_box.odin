package systems

import "../components"
import "core:time"
import rl "vendor:raylib"
import "../ui"
import "../engine"

draw_texts :: proc() {
  for &item in components.table_text_boxes.items {
    box := item.attached_to_box

    if box != nil {
      position := rl.Vector2 { box.x + box.width, box.y }

      if item.animated {
        ui.draw_animated_text_box(&item.metadata, position, item.ticks)
      } else {
        ui.draw_text_box(&item.metadata, position)
      }
    }
  }
}

update_texts :: proc() {
  to_delete: [dynamic]int

  for &item in components.table_text_boxes.items {
    time_diff := time.duration_milliseconds(time.diff(item.instanciated_at, time.now()))

    if item.animated && item.ticks != item.metadata.text_len {
      // 30ms for each letter
      item.ticks = int(time_diff / 30)
      if item.ticks > item.metadata.text_len do item.ticks = item.metadata.text_len
    }

    if item.duration != -1 && time_diff > item.duration {
      append(&to_delete, item.entity_id)
    }
  }

  for id in to_delete {
    engine.database_destroy_component(id, &components.table_text_boxes)
  }
}

