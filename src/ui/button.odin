package ui

import "core:log"
import "core:strings"
import "../engine"
import rl "vendor:raylib"


ButtonConfiguration :: struct {
  x_ratio, y_ratio: f32,
  overlay: ^engine.Overlay,
}

// BUTTON


// Draw a list of buttons centered on y and x from engine.game_state.resolution
button_draw_xy_centered_list :: proc(texts: []string, font_size: i32, on_click: proc(id: int), selection: ^int, color: rl.Color = rl.WHITE) {
  // Keyboard navigation
  if rl.IsKeyPressed(rl.KeyboardKey.UP) do selection^ = selection^ - 1 < 0 ? len(texts) - 1 : selection^ - 1
  if rl.IsKeyPressed(rl.KeyboardKey.DOWN) do selection^ = (selection^ + 1) % len(texts)

  for idx in 0..<len(texts) {
    text := texts[idx]

    selected_by_mouse, clicked := persistable_button_draw(text, { 0.25, f32(idx + 1) * 0.15, nil }, font_size, selection^ == idx, color)

    if selected_by_mouse do selection^ = idx
    if clicked do on_click(idx)
  }
}

// Draw a PERSISTABLE button with a given size and position.
// It has a selected prop which is used to enforce selected state.
// Returns 2 bools:
// - whether it's selected by the mouse
// - whether it's clicked
persistable_button_draw :: proc(text: string, position: ButtonConfiguration, font_size: i32, selected: bool, color: rl.Color = rl.WHITE) -> (bool, bool) {
  metadata          := generate_metadata(text, position, font_size)
  selected          := selected
  clicked           := false
  selected_by_mouse := false

  if rl.CheckCollisionPointRec(rl.GetMousePosition(), metadata.screen_bounds) {
    delta := rl.GetMouseDelta()

    // We don't want the button to be considered as being selected by the mouse if it just happened to be on top of it. We want the mouse to have moved to consider it "selected by mouse"
    if delta.x != 0 || delta.y != 0 {
      selected_by_mouse = true
      selected = true
    }

    if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) do clicked = true
  }

  draw_from_metadata(&metadata, font_size, selected, color)

  return selected_by_mouse, clicked
}

// Draw a simple button with a given size and position.
// Returns 2 bools:
// - whether it's selected by the mouse
// - whether it's clicked
simple_button_draw :: proc(text: string, config: ButtonConfiguration, font_size: i32, color: rl.Color = rl.WHITE) -> (bool, bool) {
  metadata          := generate_metadata(text, config, font_size)
  clicked           := false
  selected          := false

  if rl.CheckCollisionPointRec(rl.GetMousePosition(), metadata.screen_bounds) do selected = true
  if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) do clicked = true

  draw_from_metadata(&metadata, font_size, selected, color)

  return selected, clicked
}



//
// PRIVATE
//



@(private="file")
BUTTON_SPACING: i32 = 15

@(private="file")
BUTTON_LINES_THICKNESS_UNSELECTED: f32 = 2

@(private="file")
BUTTON_LINES_THICKNESS_SELECTED: f32 = 6

ButtonMetadata :: struct {
  config: ButtonConfiguration,
  padding: f32,
  ctext: cstring,
  measured_text: i32,
  box: rl.Rectangle,
  screen_bounds: rl.Rectangle,
}

@(private="file")
generate_metadata :: proc(text: string, config: ButtonConfiguration, font_size: i32) -> ButtonMetadata {
  ctext := strings.unsafe_string_to_cstring(text)
  measured_text := rl.MeasureText(ctext, font_size)
  padding := f32(font_size) / 3
  width := f32(measured_text) + 2 * padding
  height := f32(font_size) + 2 * padding

  resolution: [2]i32 = config.overlay == nil ? engine.game_state.resolution : config.overlay.resolution

  position: [2]f32 = {
    f32(resolution.x) * config.x_ratio,
    f32(resolution.y) * config.y_ratio,
  }

  offset: [2]f32 = config.overlay == nil ? { 0, 0 } : config.overlay.position

  return ButtonMetadata {
    config,
    padding,
    ctext,
    measured_text,
    rl.Rectangle { position.x - padding, position.y - padding, width, height },
    rl.Rectangle {
      position.x + offset.x,
      position.y + offset.y,
      width,
      height,
    },
  }
}

draw_from_metadata :: proc(metadata: ^ButtonMetadata, font_size: i32, selected: bool, color: rl.Color) {
  color := color

  if !selected {
    color.r /= 2
    color.g /= 2
    color.b /= 2
  }

  rl.DrawText(metadata.ctext, i32(metadata.box.x + metadata.padding), i32(metadata.box.y + metadata.padding), font_size, color)
  rl.DrawRectangleLinesEx(metadata.box, selected ? BUTTON_LINES_THICKNESS_SELECTED : BUTTON_LINES_THICKNESS_UNSELECTED, color)
}
