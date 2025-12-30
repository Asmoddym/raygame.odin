package macro

import "core:fmt"
import "engine"
import "globals"
import "enums"
import rl "vendor:raylib"



//
// SYSTEMS
//



// Input handling for default runtime systems.
input_system_main :: proc() {
  time := rl.GetFrameTime()

  // bbox := engine.database_get_component(globals.player_id, &table_bounding_boxes[globals.PLAYER_LAYER])

  // // Text box test stuff
  // if rl.IsKeyPressed(rl.KeyboardKey.A) {
  //   ui_animated_text_box_draw(
  //     "coucou c'est moi et je suis un texte animé oulala c'est rigolo !",
  //     font_size = 20,
  //     duration = 2000,
  //     attached_to_bounding_box = bbox,
  //   )
  // }
  //
  wheel_move := rl.GetMouseWheelMove()

  if wheel_move != 0 && (engine.camera.zoom >= ZOOM_INTERVAL.x && engine.camera.zoom <= ZOOM_INTERVAL.y) {
    engine.camera.zoom += wheel_move * ZOOM_SPEED

    engine.camera.zoom = min(ZOOM_INTERVAL.y, engine.camera.zoom)
    engine.camera.zoom = max(ZOOM_INTERVAL.x, engine.camera.zoom)
  }

  if rl.IsKeyDown(rl.KeyboardKey.LEFT)  do engine.camera.target.x -= 800 * time * 1 / engine.camera.zoom
  if rl.IsKeyDown(rl.KeyboardKey.RIGHT) do engine.camera.target.x += 800 * time * 1 / engine.camera.zoom
  if rl.IsKeyDown(rl.KeyboardKey.UP)    do engine.camera.target.y -= 800 * time * 1 / engine.camera.zoom
  if rl.IsKeyDown(rl.KeyboardKey.DOWN)  do engine.camera.target.y += 800 * time * 1 / engine.camera.zoom

  relative_x := engine.game_state.resolution.x - i32(rl.GetMouseX())
  relative_y := engine.game_state.resolution.y - i32(rl.GetMouseY())

  if relative_x < BORDER_OFFSET {
    engine.camera.target.x += 800 * time
  } else if relative_x > engine.game_state.resolution.x - BORDER_OFFSET {
    engine.camera.target.x -= 800 * time
  }

  if relative_y < BORDER_OFFSET {
    engine.camera.target.y += 800 * time
  } else if relative_y > engine.game_state.resolution.y - BORDER_OFFSET {
    engine.camera.target.y -= 800 * time
  }


  @(static) selection_start: [2]i32
  @(static) selecting:= false

  @(static) txt := 0

  if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
    selection_start = to_cell_position({ rl.GetMouseX(), rl.GetMouseY() })
    selecting = true
  }

  if rl.IsMouseButtonReleased(rl.MouseButton.LEFT) {
    selecting = false
  }

  size := i32(BOX_SIZE) / 2
  mouse_pos := to_cell_position({ rl.GetMouseX(), rl.GetMouseY() })

  bbox := engine.database_get_component(0, &table_bounding_boxes[4])
  bbox.box.x = f32(mouse_pos.x)
  bbox.box.y = f32(mouse_pos.y)

  if selecting {
    first_point: [2]i32 = { min(selection_start.x, mouse_pos.x), min(selection_start.y, mouse_pos.y) }
    last_point: [2]i32 = { max(selection_start.x, mouse_pos.x), max(selection_start.y, mouse_pos.y) }

ui_text_box_draw(string(rl.TextFormat("%dx%d", abs(last_point.x - first_point.x) / size, abs(last_point.y - first_point.y) / 16)), i32(18.0 * (1 / engine.camera.zoom)), bbox, 1)

    rl.DrawRectangle(first_point.x, first_point.y, last_point.x - first_point.x, last_point.y - first_point.y, rl.Color { 255, 0, 0, 100 })
  } else {
    rl.DrawRectangle(mouse_pos.x, mouse_pos.y, size, size, rl.Color { 255, 0, 0, 100 })
  }
}

to_cell_position :: proc(pos: [2]i32) -> [2]i32 {
  multiplier: f32 = 1 / engine.camera.zoom
  size := i32(BOX_SIZE) / 2

  relative_position: [2]i32 = {
    i32(multiplier * f32(pos.x - i32(engine.camera.offset.x)) + engine.camera.target.x),
    i32(multiplier * f32(pos.y - i32(engine.camera.offset.y)) + engine.camera.target.y),
  }

  return { size * (relative_position.x / size), size * (relative_position.y / size) }
}

// Handle player movement with animated sprite state
input_system_player_movement :: proc() {
  bbox            := engine.database_get_component(globals.player_id, &table_bounding_boxes[globals.PLAYER_LAYER])
  animated_sprite := engine.database_get_component(globals.player_id, &table_animated_sprites[globals.PLAYER_LAYER])

  animated_sprite.state = int(enums.Direction.NONE)

  if rl.IsKeyDown(rl.KeyboardKey.LEFT) {
    bbox.box.x -= 3
    animated_sprite.state = int(enums.Direction.LEFT)
  }

  if rl.IsKeyDown(rl.KeyboardKey.RIGHT) {
    bbox.box.x += 3
    animated_sprite.state = int(enums.Direction.RIGHT)
  }

  if rl.IsKeyDown(rl.KeyboardKey.UP) {
    bbox.box.y -= 3
    animated_sprite.state = int(enums.Direction.UP)
  }

  if rl.IsKeyDown(rl.KeyboardKey.DOWN) {
    bbox.box.y += 3
    animated_sprite.state = int(enums.Direction.DOWN)
  }
}



//
// PRIVATE
//


// CONSTANTS


// Zoom interval
@(private="file")
ZOOM_INTERVAL: [2]f32 = { 0.3, 3 }

// Zoom speed
@(private="file")
ZOOM_SPEED: f32 = 0.05

BORDER_OFFSET: i32 = 20
