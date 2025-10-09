package engine

import "core:time"
import "utl/timer"
import rl "vendor:raylib"

SystemType :: enum {
  RUNTIME,
  PAUSE,
  INTERNAL,
  SYSTEMS,
}

@(private="file")
system_registry: [SystemType][dynamic]System

System :: struct {
  recurrence_in_ms: f64,
  callback: proc(),
  last_updated_at: time.Time,
}

systems_register :: proc(type: SystemType, callback: proc(), recurrence_in_ms: f64 = -1) {
  append(&system_registry[type], System { recurrence_in_ms, callback, time.now() })
}

systems_update :: proc() {
  timer.reset(timer.Type.SYSTEM)
  now := time.now()

  if game_state.paused {
    run_systems(&system_registry[.PAUSE], now)
  } else {
    run_systems(&system_registry[.RUNTIME], now)
  }

  run_systems(&system_registry[.INTERNAL], now)

  timer.lock(timer.Type.SYSTEM)
}

@(private="file")
run_systems :: proc(list: ^[dynamic]System, now: time.Time) {
  for &system in list {
    if can_update(system, now) {
      system.callback()
      system.last_updated_at = now
    }
  }
}

@(private="file")
can_update :: proc(system: System, now: time.Time) -> bool {
  return time.duration_milliseconds(time.diff(system.last_updated_at, now)) > system.recurrence_in_ms
}

// Internal systems

systems_internal_pause_toggle :: proc() {
  if rl.IsKeyPressed(.ESCAPE) do game_state.paused = !game_state.paused
}

