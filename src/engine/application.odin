package engine

import rl "vendor:raylib"
import "core:fmt"
import "core:strings"
import "utl/timer"

DEBUG::#config(DEBUG, false)

// -----
// Registry and entity management
// -----


init :: proc() {
  rl.SetConfigFlags({rl.ConfigFlag.VSYNC_HINT, rl.ConfigFlag.WINDOW_HIGHDPI})

  rl.InitWindow(1600, 900, "coucou")
}

// -----
// Run
// -----

run :: proc() {
  for !rl.WindowShouldClose() {
    timer.reset(timer.Type.FRAME)

    rl.BeginDrawing()
    rl.ClearBackground(rl.BLACK)

    systems_update()

    timer.lock(timer.Type.FRAME)
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
