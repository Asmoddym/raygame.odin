package ui

import "core:strings"
import rl "vendor:raylib"

@(private="file")
BUTTON_SPACING: f32 = 20

draw_x_centered_button :: proc(text: string, width: i32, y: f32, font_size: i32, on_click: proc(), color: rl.Color = rl.WHITE) {
  ctext := strings.unsafe_string_to_cstring(text)
  measured_size := rl.MeasureText(ctext, font_size)
  x := f32(width / 2 - measured_size / 2)
  draw_button(text, rl.Vector2 { x, y }, font_size, on_click, color)
}

draw_button :: proc(text: string, position: rl.Vector2, font_size: i32, on_click: proc(), color: rl.Color = rl.WHITE) {
  color := color
  ctext := strings.unsafe_string_to_cstring(text)
  measured_size := rl.MeasureText(ctext, font_size)

  width: f32 = f32(measured_size + 2 * i32(BUTTON_SPACING))
  height: f32 = f32(font_size + 2 * i32(BUTTON_SPACING))
  hitbox := rl.Rectangle { position.x - BUTTON_SPACING, position.y - BUTTON_SPACING, width, height }

  if rl.CheckCollisionPointRec(rl.GetMousePosition(), hitbox) {
    color.a /= 3

    if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) do on_click()
  }

  rl.DrawText(ctext, i32(position.x), i32(position.y), font_size, color)
  rl.DrawRectangleLinesEx(hitbox, 2, color)
}
