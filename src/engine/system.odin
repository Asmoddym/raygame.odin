package engine

import "core:fmt"
import "core:time"
import "utl/timer"
import rl "vendor:raylib"
import "../ui"

System :: struct {
  recurrence_in_ms: f64,
  callback: proc(),
  last_updated_at: time.Time,
  run_when_paused: bool,
}

@(private="file")
systems: [dynamic]System

systems_register :: proc(callback: proc(), recurrence_in_ms: f64 = -1, run_when_paused: bool = false) {
  append(&systems, System { recurrence_in_ms, callback, time.now(), run_when_paused })
}

systems_update :: proc() {
  timer.reset(timer.Type.SYSTEM)

  now := time.now()

  for &system in systems {
    if (can_update(system, now)) {
      system.callback()
      system.last_updated_at = now
    }
  }

  internal_system()

  timer.lock(timer.Type.SYSTEM)
}

@(private="file")
can_update :: proc(system: System, now: time.Time) -> bool {
  return time.duration_milliseconds(time.diff(system.last_updated_at, now)) > system.recurrence_in_ms
}

systems_on_pause :: proc() {
  timer.reset(timer.Type.SYSTEM)
  internal_system()
  timer.lock(timer.Type.SYSTEM)
}

@(private="file")
internal_system :: proc() {
  if game_state.paused {
    ui.draw_x_centered_button("Exit", game_state.screen_width, f32(game_state.screen_height / 2), font_size = 40, on_click = proc() { game_state.closed = true })
  }

  if rl.IsKeyPressed(.ESCAPE) do game_state.paused = !game_state.paused
}
