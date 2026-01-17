package ui

import "core:strings"
import "../engine"
import rl "vendor:raylib"


// BUTTON


// Draw a list of buttons centered on y and x from engine.game_state.resolution
button_draw_xy_centered_list :: proc(texts: []string, font_size: i32, on_click: proc(id: int), selection: ^int, color: rl.Color = rl.WHITE) {
  resolution               := engine.game_state.resolution
  padding                  := i32(font_size / 3)
  text_height_with_padding := font_size + 2 * padding

  // Add each text with padding and spacing
  block_height             := i32(len(texts)) * text_height_with_padding + (i32(len(texts) - 1) * BUTTON_SPACING)

  // The calculation is made from the text, not the box. We have to remove the padding for the first iteration
  beginning_y              := resolution.y / 2 - block_height / 2 + i32(padding)

  // Keyboard navigation
  if rl.IsKeyPressed(rl.KeyboardKey.UP) do selection^ = selection^ - 1 < 0 ? len(texts) - 1 : selection^ - 1
  if rl.IsKeyPressed(rl.KeyboardKey.DOWN) do selection^ = (selection^ + 1) % len(texts)

  for idx in 0..<len(texts) {
    text := texts[idx]
    measured_text := rl.MeasureText(strings.unsafe_string_to_cstring(text), font_size)
    position := rl.Vector2 {
      f32(resolution.x / 2 - measured_text / 2),
      f32(beginning_y),
    }

    selected_by_mouse, clicked := button_draw(text, position, font_size, selection^ == idx, color)

    if selected_by_mouse do selection^ = idx
    if clicked do on_click(idx)

    beginning_y += text_height_with_padding + BUTTON_SPACING
  }
}

// Draw a button with a given size and position.
// Returns true if button was clicked.
button_draw :: proc(text: string, position: rl.Vector2, font_size: i32, selected: bool, color: rl.Color = rl.WHITE) -> (bool, bool) {
  padding := i32(font_size / 3)
  thickness: f32 = 2

  color := color
  ctext := strings.unsafe_string_to_cstring(text)
  measured_text := rl.MeasureText(ctext, font_size)

  width: f32 = f32(measured_text + 2 * padding)
  height: f32 = f32(font_size + 2 * padding)
  box := rl.Rectangle { f32(position.x - f32(padding)), f32(position.y - f32(padding)), width, height }

  clicked := false
  selected_by_mouse := false

  if selected {
    thickness = 6
  } else {
    color.r /= 2
    color.g /= 2
    color.b /= 2
  }

  if rl.CheckCollisionPointRec(rl.GetMousePosition(), { position.x, position.y, width, height }) {
    delta := rl.GetMouseDelta()

    // We don't want the button to be considered as being selected by the mouse if it just happened to be on top of it. We want the mouse to have moved to consider it "selected by mouse"
    if delta.x != 0 && delta.y != 0 do selected_by_mouse = true

    if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
      clicked = true
    }
  }

  rl.DrawText(ctext, i32(position.x), i32(position.y), font_size, color)
  rl.DrawRectangleLinesEx(box, thickness, color)

  return selected_by_mouse, clicked
}



//
// PRIVATE
//



@(private="file")
BUTTON_SPACING: i32 = 15

