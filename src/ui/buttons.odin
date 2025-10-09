package ui

import "core:strings"
import rl "vendor:raylib"
import "../engine"

@(private="file")
BUTTON_SPACING: i32 = 15

@(private="file")
BUTTON_PADDING: i32 = 15

draw_xy_centered_button_list :: proc(texts: []string, font_size: i32, on_click: []proc(), selected: int = -1, color: rl.Color = rl.WHITE) {
  padding := i32(font_size / 3)
  text_height_with_padding := font_size + 2 * padding

  // Add each text with padding and spacing
  block_height := i32(len(texts)) * text_height_with_padding + (i32(len(texts) - 1) * BUTTON_SPACING)

  // The calculation is made from the text, not the box. We have to remove BUTTON_PADDING for the first iteration
  beginning_y := engine.game_state.resolution.y / 2 - block_height / 2 + i32(BUTTON_PADDING)

  for idx in 0..<len(texts) {
    text := texts[idx]
    measured_text := rl.MeasureText(strings.unsafe_string_to_cstring(text), font_size)
    position := rl.Vector2 {
      f32(engine.game_state.resolution.x / 2 - measured_text / 2),
      f32(beginning_y),
    }

    draw_button(text, position, font_size, on_click[idx], selected == idx, color)
    beginning_y += text_height_with_padding + BUTTON_SPACING
  }
}

draw_button :: proc(text: string, position: rl.Vector2, font_size: i32, on_click: proc(), selected: bool, color: rl.Color = rl.WHITE) {
  padding := i32(font_size / 3)
  thickness: f32 = 2

  color := color
  ctext := strings.unsafe_string_to_cstring(text)
  measured_text := rl.MeasureText(ctext, font_size)

  width: f32 = f32(measured_text + 2 * padding)
  height: f32 = f32(font_size + 2 * padding)
  box := rl.Rectangle { f32(position.x - f32(padding)), f32(position.y - f32(padding)), width, height }

  //|| rl.CheckCollisionPointRec(rl.GetMousePosition(), box) {
  if selected {
    thickness = 6

    // if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) do on_click()
    if rl.IsKeyPressed(.ENTER) do on_click()
  } else {
    color.a /= 2
  }

  rl.DrawText(ctext, i32(position.x), i32(position.y), font_size, color)
  rl.DrawRectangleLinesEx(box, thickness, color)
}
