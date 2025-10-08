package engine

import rl "vendor:raylib"
import "core:fmt"
import "core:strings"
import "utl/timer"

GameState :: struct {
  paused: bool,
  closed: bool,
  resolution: [2]i32,
}

game_state: GameState

FULLSCREEN :=false 

init :: proc() {
  rl.SetConfigFlags({rl.ConfigFlag.VSYNC_HINT, rl.ConfigFlag.WINDOW_HIGHDPI})

  rl.ChangeDirectory("resources")

  size: [2]i32

  if FULLSCREEN {
    size = { 0, 0 }
  } else {
    size = { 1600, 900 }
  }

  rl.InitWindow(size.x, size.y, "coucou")
  game_state = GameState { false, false, { size.x == 0 ? rl.GetMonitorWidth(rl.GetCurrentMonitor()) : size.x, size.y == 0 ? rl.GetMonitorHeight(rl.GetCurrentMonitor()) : size.y } }

  if (size.x == 0 && size.y == 0) {
    rl.ToggleBorderlessWindowed()
  }

  rl.SetExitKey(.KEY_NULL)

  init_camera(game_state.resolution)
}

run :: proc() {
  for !rl.WindowShouldClose() && !game_state.closed {
    paused := game_state.paused
    timer.reset(timer.Type.FRAME)
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
}
