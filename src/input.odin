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

  bbox := engine.database_get_component(globals.player_id, &table_bounding_boxes[globals.PLAYER_LAYER])

  // Text box test stuff
  if rl.IsKeyPressed(rl.KeyboardKey.A) {
    ui_animated_text_box_draw(
      "coucou c'est moi et je suis un texte animé oulala c'est rigolo !",
      font_size = 20,
      duration = 2000,
      attached_to_bounding_box = bbox,
    )
  }

  wheel_move := rl.GetMouseWheelMove()

  if wheel_move != 0 && (engine.camera.zoom >= ZOOM_INTERVAL.x && engine.camera.zoom <= ZOOM_INTERVAL.y) {
    engine.camera.zoom += wheel_move * ZOOM_SPEED

    engine.camera.zoom = min(ZOOM_INTERVAL.y, engine.camera.zoom)
    engine.camera.zoom = max(ZOOM_INTERVAL.x, engine.camera.zoom)
  }

  if rl.IsKeyDown(rl.KeyboardKey.LEFT) {
    engine.camera.target.x -= 800 * time
  }

  if rl.IsKeyDown(rl.KeyboardKey.RIGHT) {
    engine.camera.target.x += 800 * time
  }

  if rl.IsKeyDown(rl.KeyboardKey.UP) {
    engine.camera.target.y -= 800 * time
  }

  if rl.IsKeyDown(rl.KeyboardKey.DOWN) {
    engine.camera.target.y += 800 * time
  }

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

  size := i32(BOX_SIZE) / 2

  multiplier: f32 = 1 / engine.camera.zoom

  mouse_pos:= [2]i32 {
    i32(multiplier * f32(rl.GetMouseX() - i32(engine.camera.offset.x)) + engine.camera.target.x),
    i32(multiplier * f32(rl.GetMouseY() - i32(engine.camera.offset.y)) + engine.camera.target.y),
  }

  rl.DrawRectangle(size * (mouse_pos.x / size), size * (mouse_pos.y / size), size, size, rl.Color { 255, 255, 255, 100 })
}

// Handle player movement with animated sprite state
input_system_player_movement :: proc() {
  bbox            := engine.database_get_component(globals.player_id, &table_bounding_boxes[globals.PLAYER_LAYER])
  animated_sprite := engine.database_get_component(globals.player_id, &table_animated_sprites[globals.PLAYER_LAYER])

  animated_sprite.state = int(enums.Direction.NONE)

  // if rl.IsKeyDown(rl.KeyboardKey.LEFT) {
  //   bbox.box.x -= 3
  //   animated_sprite.state = int(enums.Direction.LEFT)
  // }
  //
  // if rl.IsKeyDown(rl.KeyboardKey.RIGHT) {
  //   bbox.box.x += 3
  //   animated_sprite.state = int(enums.Direction.RIGHT)
  // }
  //
  // if rl.IsKeyDown(rl.KeyboardKey.UP) {
  //   bbox.box.y -= 3
  //   animated_sprite.state = int(enums.Direction.UP)
  // }
  //
  // if rl.IsKeyDown(rl.KeyboardKey.DOWN) {
  //   bbox.box.y += 3
  //   animated_sprite.state = int(enums.Direction.DOWN)
  // }
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
