package engine

import rand "core:math/rand"
import "utl/timer"
import "core:fmt"
import "core:time"
import "core:strings"
import rl "vendor:raylib"


// Main game state struct, storing game and window states
game_state: GameState

// Init engine. Must be called first
init :: proc() {
  rl.ChangeDirectory("resources")

  game_state.closed = false

  rand.reset(rand_seed)

  window_init()
  camera_init()
}

// Run engine after initial configuration
run :: proc() {
  previous_state: GameState = game_state

  for !rl.WindowShouldClose() && !game_state.closed {
    timer.reset(timer.Type.FRAME)
    application_game_state_process_changes(previous_state)
    previous_state = game_state

    rl.BeginDrawing()

    application_process_frame()
    timer.lock(timer.Type.FRAME)

    when ODIN_DEBUG do application_debug_render_information()

    rl.EndDrawing()
  }
}

// Unload all data before exiting program
unload :: proc() {
  assets_unload()
}



//
// PRIVATE
//



@(private="file")
GameState :: struct {
  closed: bool,
  borderless_window: bool,
  fullscreen: bool,
  resolution: [2]i32,
  current_scene: ^Scene,
}


// CONSTANTS


// Random seed
@(private="file")
rand_seed: u64 = 16


// FRAME PROCESSING


// Process frame (with 2D mode depending on systems type)
@(private="file")
application_process_frame :: proc() {
  now := time.now()
  rl.ClearBackground(rl.BLACK)

  timer.reset(timer.Type.SYSTEM)

  if game_state.current_scene.uses_camera {
    // 2D mode takes some time to process, so we want to separate it from the systems timer
    sub_timer := time.now()
    // rl.BeginMode2D(camera)

    // Using this updates the engine.current_camera pointer
    camera_set_current_camera(&camera)
    timer.add_offset(timer.Type.SYSTEM, time.duration_milliseconds(time.diff(sub_timer, time.now())))

    system_update(game_state.current_scene.id, now)

    sub_timer = time.now()
    rl.EndMode2D()
    timer.add_offset(timer.Type.SYSTEM, time.duration_milliseconds(time.diff(sub_timer, time.now())))
  } else {
    system_update(game_state.current_scene.id, now)
  }

  timer.reset(timer.Type.OVERLAY)
  system_overlay_update(game_state.current_scene.id, now)
  timer.lock(timer.Type.OVERLAY)

  timer.lock(timer.Type.SYSTEM)
}


// DEBUG


// Render FPS, resolution and window state (only on debug compilation mode)
@(private="file")
application_debug_render_information :: proc() {
  texts:     [dynamic]string
  font_size: f32 = 20

  append(&texts, fmt.tprintf("%d FPS", rl.GetFPS()))
  append(&texts, fmt.tprintf("\nsystem : %.03fms", timer.as_milliseconds(timer.Type.SYSTEM)))
  append(&texts, fmt.tprintf("\nframe  : %.03fms", timer.as_milliseconds(timer.Type.FRAME)))
  append(&texts, fmt.tprintf("\noverlay: %.03fms", timer.as_milliseconds(timer.Type.OVERLAY)))
  // append(&texts, fmt.tprintf("\nres: %dx%d\ntarget: %f, %f (zoom: %f)\noffset: %f, %f", game_state.resolution.x, game_state.resolution.y, camera.target.x, camera.target.y, camera.zoom, camera.offset.x, camera.offset.y))

  str, err := strings.concatenate(texts[:])

  if err == nil {
    measure := rl.MeasureTextEx(rl.GetFontDefault(), strings.unsafe_string_to_cstring(str), font_size, font_size / 10)
    pos: [2]i32 = { 5, game_state.resolution.y - i32(measure.y) - 15 }

    rl.DrawRectangle(pos.x, pos.y, i32(measure.x) + 10, i32(measure.y) + 10, rl.BLACK)
    // rl.DrawRectangleLines(pos.x, pos.y, i32(measure.x) + 10, i32(measure.y) + 10, rl.WHITE)

    rl.DrawText(strings.unsafe_string_to_cstring(str), pos.x + 5, pos.y + 5, i32(font_size), rl.GREEN)
  }
}


// GAME STATE


@(private="file")
application_game_state_process_changes :: proc(previous_state: GameState) {
  if game_state.borderless_window != previous_state.borderless_window {
    game_state.fullscreen = false
    window_toggle_mode(game_state.borderless_window, proc() { rl.ToggleBorderlessWindowed() })
  } else if game_state.fullscreen != previous_state.fullscreen {
    game_state.borderless_window = false
    window_toggle_mode(game_state.fullscreen, proc() { rl.ToggleFullscreen() })
  }
}
