package ui

import "core:strings"
import "../engine"
import "../engine/utl"
import rl "vendor:raylib"


// STRUCT


// Button metadata struct.
ButtonMetadata :: struct {
  overlay: ^engine.Overlay,
  hook: [2]f32,
  padding: f32,
  ctext: cstring,
  measured_text: rl.Vector2,
  box: rl.Rectangle,
  screen_bounds: rl.Rectangle,
  font_size: i32,
  color: rl.Color,
}


// PROCS


// Draw a PERSISTABLE button from its ID.
// It has a selected prop which is used to enforce selected state.
// Returns 2 bools:
// - whether it's selected by the mouse
// - whether it's clicked
persistable_button_draw :: proc(id: int, overlay: ^engine.Overlay, selected: bool) -> (bool, bool) {
  registry, _ := &button_registry[overlay]
  metadata, _ := &registry[id]
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

  draw_from_metadata(metadata, selected)

  return selected_by_mouse, clicked
}

// Draw a simple button from its ID.
// Returns 2 bools:
// - whether it's selected by the mouse
// - whether it's clicked
simple_button_draw :: proc(id: int, overlay: ^engine.Overlay) -> (bool, bool) {
  registry, _ := &button_registry[overlay]
  metadata, _ := &registry[id]
  clicked           := false
  selected          := false

  if rl.CheckCollisionPointRec(rl.GetMousePosition(), metadata.screen_bounds) {
    selected = true
    if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) do clicked = true
  }

  draw_from_metadata(metadata, selected)

  return selected, clicked
}

// Create a button.
// `id` is a static ID defining the button, it's not returned from anything.
simple_button_create :: proc(id: int, text: string, overlay: ^engine.Overlay, hook: [2]f32, font_size: i32, color: rl.Color = rl.WHITE) {
  if !(overlay in button_registry) {
    button_registry[overlay] = make(map[int]ButtonMetadata)
  }

  registry, _ := &button_registry[overlay]
  registry[id] = generate_metadata(text, overlay, hook, font_size, color)
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

@(private="file")
button_registry: map[^engine.Overlay]map[int]ButtonMetadata

// Generate a button metadata to store them in the registry.
@(private="file")
generate_metadata :: proc(text: string, overlay: ^engine.Overlay, hook: [2]f32, font_size: i32, color: rl.Color) -> ButtonMetadata {
  ctext := strings.unsafe_string_to_cstring(text)
  measured_text := rl.MeasureTextEx(rl.GetFontDefault(), ctext, f32(font_size), f32(font_size / 10))
  padding := f32(font_size) / 2.5
  width := measured_text.x + 2 * padding
  height := measured_text.y + 2 * padding

  position := utl.position_calculate(hook,
    overlay == nil ? engine.game_state.resolution : overlay.resolution,
    { i32(width), i32(height) },
    )

  offset: [2]f32 = overlay == nil ? { 0, 0 } : overlay.position

  return ButtonMetadata {
    overlay,
    hook,
    padding,
    ctext,
    measured_text,
    rl.Rectangle { position.x, position.y, width, height },
    rl.Rectangle {
      position.x + offset.x,
      position.y + offset.y,
      width,
      height,
    },
    font_size,
    color,
  }
}

// Draw a button from its metadata and selected state.
@(private="file")
draw_from_metadata :: proc(metadata: ^ButtonMetadata, selected: bool) {
  color := metadata.color

  if !selected {
    color.r /= 2
    color.g /= 2
    color.b /= 2
  }

  rl.DrawText(metadata.ctext, i32(metadata.box.x + metadata.padding), i32(metadata.box.y + metadata.padding), metadata.font_size, color)
  rl.DrawRectangleLinesEx(metadata.box, selected ? BUTTON_LINES_THICKNESS_SELECTED : BUTTON_LINES_THICKNESS_UNSELECTED, color)
}
