package ui

import "core:strings"
import "../engine"
import rl "vendor:raylib"


// BUTTON


// Draw a list of buttons centered on y and x from engine.game_state.resolution
button_draw_xy_centered_list :: proc(texts: []string, font_size: i32, on_click: []proc(), selected: int, resolution: [2]i32 = { 0, 0 }, color: rl.Color = rl.WHITE) {
  resolution := resolution
  if resolution.x == 0 do resolution = engine.game_state.resolution

  padding := i32(font_size / 3)
  text_height_with_padding := font_size + 2 * padding


  // Add each text with padding and spacing
  block_height := i32(len(texts)) * text_height_with_padding + (i32(len(texts) - 1) * BUTTON_SPACING)

  // The calculation is made from the text, not the box. We have to remove the padding for the first iteration
  beginning_y := resolution.y / 2 - block_height / 2 + i32(padding)

  for idx in 0..<len(texts) {
    text := texts[idx]
    measured_text := rl.MeasureText(strings.unsafe_string_to_cstring(text), font_size)
    position := rl.Vector2 {
      f32(resolution.x / 2 - measured_text / 2),
      f32(beginning_y),
    }

    button_draw(text, position, font_size, on_click[idx], selected == idx, color)
    beginning_y += text_height_with_padding + BUTTON_SPACING
  }
}

// Draw a button with a given size and position
button_draw :: proc(text: string, position: rl.Vector2, font_size: i32, on_click: proc(), selected: bool, color: rl.Color = rl.WHITE) {
  padding := i32(font_size / 3)
  thickness: f32 = 2

  color := color
  ctext := strings.unsafe_string_to_cstring(text)
  measured_text := rl.MeasureText(ctext, font_size)

  width: f32 = f32(measured_text + 2 * padding)
  height: f32 = f32(font_size + 2 * padding)
  box := rl.Rectangle { f32(position.x - f32(padding)), f32(position.y - f32(padding)), width, height }

  if selected {
    thickness = 6
  } else {
    color.r /= 2
    color.g /= 2
    color.b /= 2
  }

  rl.DrawText(ctext, i32(position.x), i32(position.y), font_size, color)
  rl.DrawRectangleLinesEx(box, thickness, color)
}



//
// PRIVATE
//



@(private="file")
BUTTON_SPACING: i32 = 15

