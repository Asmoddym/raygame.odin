package engine

import rl "vendor:raylib"
import "core:fmt"
import "core:strings"
import "utl/timer"

GameState :: struct {
  paused: bool,
  closed: bool,
  borderless_window: bool,
  resolution: [2]i32,
}

game_state: GameState

init_window :: proc(resolution: [2]i32, borderless_window: bool) {
  rl.InitWindow(resolution.x, resolution.y, "coucou")

  game_state.resolution = {
    resolution.x == 0 ? rl.GetMonitorWidth(rl.GetCurrentMonitor()) : resolution.x,
    resolution.y == 0 ? rl.GetMonitorHeight(rl.GetCurrentMonitor()) : resolution.y,
  }

  game_state.borderless_window = borderless_window
  if borderless_window do rl.ToggleBorderlessWindowed()

    rl.SetExitKey(.KEY_NULL)
}

init :: proc() {
  rl.SetConfigFlags({rl.ConfigFlag.VSYNC_HINT, rl.ConfigFlag.WINDOW_HIGHDPI})

  rl.ChangeDirectory("resources")

  game_state.paused = false
  game_state.closed = false

  init_window({ 1600, 900 }, false)
  init_camera(game_state.resolution)
}

run :: proc() {
  previous_state: GameState = game_state

  for !rl.WindowShouldClose() && !game_state.closed {
    timer.reset(timer.Type.FRAME)
    process_game_state_changes(previous_state)

    previous_state = game_state
    paused := game_state.paused

    rl.BeginDrawing()

    if !paused do rl.BeginMode2D(camera)

    rl.ClearBackground(rl.BLACK)

    systems_update()

    timer.lock(timer.Type.FRAME)

    if !paused do rl.EndMode2D()

    when ODIN_DEBUG {
      render_debug()
    }

    rl.EndDrawing()
  }
}

render_debug :: proc() {
  texts: [int(timer.Type.TYPES) + 1]string
  texts[0] = fmt.tprintf("%d FPS", rl.GetFPS())

  texts[1 + int(timer.Type.SYSTEM)] = fmt.tprintf("\nsystem : %.03fms", timer.as_milliseconds(timer.Type.SYSTEM))
  texts[1 + int(timer.Type.FRAME)]  = fmt.tprintf("\nframe  : %.03fms", timer.as_milliseconds(timer.Type.FRAME))

  str, err := strings.concatenate(texts[:])

  if err == nil {
    rl.DrawText(strings.unsafe_string_to_cstring(str), 10, 10, 20, rl.LIME)
  }

  rl.DrawText(strings.unsafe_string_to_cstring(fmt.tprintf("Res: %dx%d", game_state.resolution.x, game_state.resolution.y)), 10, game_state.resolution.y - 28, 20, rl.WHITE)
}

process_game_state_changes :: proc(previous_state: GameState) {
  if game_state.borderless_window != previous_state.borderless_window {
    rl.ToggleBorderlessWindowed()

    if game_state.borderless_window {
      game_state.resolution = { rl.GetMonitorWidth(rl.GetCurrentMonitor()), rl.GetMonitorHeight(rl.GetCurrentMonitor()) }
      rl.SetWindowSize(game_state.resolution.x, game_state.resolution.y)
    } else {
      game_state.resolution = { 1600, 900 }
      rl.SetWindowSize(game_state.resolution.x, game_state.resolution.y)
    }

    init_camera(game_state.resolution)
  }
}
