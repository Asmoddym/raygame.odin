package components

import "core:time"
import "../engine"
import rl "vendor:raylib"

init_text_box :: proc(component: ^Component_TextBox, text: string, font_size: i32, attached_to_entity_id: int, duration: f64 = -1, color: rl.Color = rl.WHITE) {
  component.text = text
  component.duration = duration
  component.size = font_size
  component.instanciated_at = time.now()
  component.attached_to_box = &engine.database_get_component(attached_to_entity_id, &table_bounding_boxes).box

  component.animated = false
  component.ticks = 0
}

init_animated_text_box :: proc(component: ^Component_TextBox, text: string, font_size: i32, attached_to_entity_id: int, duration: f64 = -1, color: rl.Color = rl.WHITE) {
  init_text_box(component, text, font_size, attached_to_entity_id, duration, color)

  component.animated = true
}
