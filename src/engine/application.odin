package engine

import "core:time"
import "utl/timer"
import "core:fmt"
import "core:strings"
import rl "vendor:raylib"


// Main game state struct, storing game and window states
game_state: GameState

// Init engine. Must be called first
init :: proc() {
  rl.ChangeDirectory("resources")

  game_state.paused = false
  game_state.closed = false

  application_window_init({ 1600, 900 })
  camera_init(game_state.resolution)
}

// Run engine after initial configuration
run :: proc() {
  previous_state: GameState = game_state

  for !rl.WindowShouldClose() && !game_state.closed {
    timer.reset(timer.Type.FRAME)
    application_game_state_process_changes(previous_state)
    previous_state = game_state

    application_run_frame()
  }
}



//
// PRIVATE
//



@(private="file")
GameState :: struct {
  paused: bool,
  closed: bool,
  borderless_window: bool,
  fullscreen: bool,
  resolution: [2]i32,

  drawable_layers: [5]rl.RenderTexture,
}


// WINDOW


// Initialize window from a resolution
@(private="file")
application_window_init :: proc(resolution: [2]i32) {
  rl.SetConfigFlags({rl.ConfigFlag.VSYNC_HINT, rl.ConfigFlag.WINDOW_HIGHDPI})
  rl.InitWindow(resolution.x, resolution.y, "coucou")

  game_state.resolution = {
    resolution.x == 0 ? rl.GetMonitorWidth(rl.GetCurrentMonitor()) : resolution.x,
    resolution.y == 0 ? rl.GetMonitorHeight(rl.GetCurrentMonitor()) : resolution.y,
  }

  application_game_state_init_drawable_layers()

  game_state.borderless_window = false

  rl.SetExitKey(.KEY_NULL)
}

// Generic screen mode switcher.
// Resets resolution and initializes camera independently from the selected mode.
// toggler contains a proc performing the actual switch.
@(private="file")
application_window_toggle_mode :: proc(toggle: bool, toggler: proc()) {
  if toggle {
    game_state.resolution = { rl.GetMonitorWidth(rl.GetCurrentMonitor()), rl.GetMonitorHeight(rl.GetCurrentMonitor()) }
    rl.SetWindowSize(game_state.resolution.x, game_state.resolution.y)
    toggler()
  } else {
    toggler()
    game_state.resolution = { 1600, 900 }
    rl.SetWindowSize(game_state.resolution.x, game_state.resolution.y)
  }

  camera_init_offset(game_state.resolution)
  application_game_state_init_drawable_layers(regenerate = true)
}



// FRAME PROCESSING



application_run_frame :: proc() {
  now := time.now()

  if game_state.paused {
    rl.BeginDrawing()
    rl.ClearBackground(rl.BLACK)

    timer.reset(timer.Type.SYSTEM)
    systems_run(.PAUSE, now)
    timer.lock(timer.Type.SYSTEM)

    when ODIN_DEBUG do application_debug_render_information()
    rl.EndDrawing()
  } else {
    timer.reset(timer.Type.SYSTEM)
    systems_run(.RUNTIME, now)

    rl.BeginDrawing()
    rl.BeginMode2D(camera)
    rl.ClearBackground(rl.BLACK)

    systems_run(.DRAW, now)
    timer.lock(timer.Type.SYSTEM)
    timer.lock(timer.Type.FRAME)

    rl.EndMode2D()

    when ODIN_DEBUG do application_debug_render_information()
    rl.EndDrawing()
  }

  systems_run(.INTERNAL, now)

  timer.lock(timer.Type.SYSTEM)

}


// DEBUG


// Render FPS, resolution and window state (only on debug compilation mode)
@(private="file")
application_debug_render_information :: proc() {
  texts: [int(timer.Type.TYPES) + 1]string
  texts[0] = fmt.tprintf("%d FPS", rl.GetFPS())

  texts[1 + int(timer.Type.SYSTEM)] = fmt.tprintf("\nsystem : %.03fms", timer.as_milliseconds(timer.Type.SYSTEM))
  texts[1 + int(timer.Type.FRAME)]  = fmt.tprintf("\nframe  : %.03fms", timer.as_milliseconds(timer.Type.FRAME))

  str, err := strings.concatenate(texts[:])

  if err == nil {
    rl.DrawText(strings.unsafe_string_to_cstring(str), 10, 10, 20, rl.LIME)
  }

  rl.DrawText(strings.unsafe_string_to_cstring(fmt.tprintf("Res: %dx%d (%s)", game_state.resolution.x, game_state.resolution.y, game_state.fullscreen ? "Fullscreen" : (game_state.borderless_window ? "Borderless" : "windowed"))), 10, game_state.resolution.y - 28, 20, rl.WHITE)
}


// GAME STATE


@(private="file")
application_game_state_process_changes :: proc(previous_state: GameState) {
  if game_state.borderless_window != previous_state.borderless_window {
    game_state.fullscreen = false
    application_window_toggle_mode(game_state.borderless_window, proc() { rl.ToggleBorderlessWindowed() })
  } else if game_state.fullscreen != previous_state.fullscreen {
    game_state.borderless_window = false
    application_window_toggle_mode(game_state.fullscreen, proc() { rl.ToggleFullscreen() })
  }
}

@(private="file")
application_game_state_init_drawable_layers :: proc(regenerate: bool = false) {
  for &layer in game_state.drawable_layers {
    if regenerate do rl.UnloadRenderTexture(layer)

    layer = rl.LoadRenderTexture(game_state.resolution.x, game_state.resolution.y)
  }
}
