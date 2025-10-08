package engine

import rl "vendor:raylib"
import "core:fmt"
import "core:strings"
import "utl/timer"

GameState :: struct {
  paused: bool,
  closed: bool,
  screen_width: i32,
  screen_height: i32,
}

game_state: GameState

init :: proc() {
  rl.SetConfigFlags({rl.ConfigFlag.VSYNC_HINT, rl.ConfigFlag.WINDOW_HIGHDPI})

  rl.ChangeDirectory("resources")
  rl.InitWindow(0, 0, "coucou")

  game_state = GameState { false, false, rl.GetMonitorWidth(rl.GetCurrentMonitor()), rl.GetMonitorHeight(rl.GetCurrentMonitor()) }
  rl.ToggleBorderlessWindowed()

  rl.SetExitKey(.KEY_NULL)

  init_camera(game_state.screen_width, game_state.screen_height)
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
