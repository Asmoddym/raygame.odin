package engine

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

  game_state.in_blocking_overlay = false
  game_state.closed = false

  application_window_init({ 1024, 768})
  camera_init(game_state.resolution)
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
  in_blocking_overlay: bool,
  closed: bool,
  borderless_window: bool,
  fullscreen: bool,
  resolution: [2]i32,
}


// FRAME PROCESSING


// Process frame (with 2D mode depending on systems type)
@(private="file")
application_process_frame :: proc() {
  now := time.now()
  rl.ClearBackground(rl.BLACK)

  timer.reset(timer.Type.SYSTEM)

  // 2D mode takes some time to process, so we want to separate it from the systems timer
  if !game_state.in_blocking_overlay {
    sub_timer := time.now()
    rl.BeginMode2D(camera)
    timer.add_offset(timer.Type.SYSTEM, time.duration_milliseconds(time.diff(sub_timer, time.now())))

    systems_update(.RUNTIME, now)

    sub_timer = time.now()
    rl.EndMode2D()
    timer.add_offset(timer.Type.SYSTEM, time.duration_milliseconds(time.diff(sub_timer, time.now())))
  }

  systems_update(.OVERLAY, now)
  systems_update(.INTERNAL, now)

  timer.lock(timer.Type.SYSTEM)
}


// WINDOW


// Initialize window from a resolution
@(private="file")
application_window_init :: proc(resolution: [2]i32) {
  rl.InitWindow(resolution.x, resolution.y, "coucou")

  rl.SetTargetFPS(rl.GetMonitorRefreshRate(rl.GetCurrentMonitor()))

  game_state.resolution = {
    resolution.x == 0 ? rl.GetMonitorWidth(rl.GetCurrentMonitor()) : resolution.x,
    resolution.y == 0 ? rl.GetMonitorHeight(rl.GetCurrentMonitor()) : resolution.y,
  }

  game_state.borderless_window = false

  rl.SetExitKey(.KEY_NULL)
}

// Generic screen mode switcher.
// Resets resolution and initializes camera independently from the selected mode.
// toggler contains a proc performing the actual switch.
@(private="file")
application_window_toggle_mode :: proc(toggle: bool, toggler: proc()) {
  if toggle {
    when ODIN_OS == .Darwin do toggler()

    game_state.resolution = { rl.GetMonitorWidth(rl.GetCurrentMonitor()), rl.GetMonitorHeight(rl.GetCurrentMonitor()) }
    rl.SetWindowSize(game_state.resolution.x, game_state.resolution.y)

    when ODIN_OS == .Windows do toggler()
  } else {
    toggler()
    game_state.resolution = { 1024, 768 }
    rl.SetWindowSize(game_state.resolution.x, game_state.resolution.y)
  }

  camera_init_offset(game_state.resolution)
  rl.SetConfigFlags({ rl.ConfigFlag.WINDOW_HIGHDPI })
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
