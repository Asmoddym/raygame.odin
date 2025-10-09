package engine

import "core:time"
import "utl/timer"
import rl "vendor:raylib"

System :: struct {
  recurrence_in_ms: f64,
  callback: proc(),
  last_updated_at: time.Time,
}

SystemRegistry :: struct {
  runtime: [dynamic]System,
  pause: [dynamic]System,
  internal: [dynamic]System,
}

@(private="file")
systems: SystemRegistry

systems_register :: proc(callback: proc(), recurrence_in_ms: f64 = -1) {
  append(&systems.runtime, System { recurrence_in_ms, callback, time.now() })
}

systems_register_pause_system :: proc(callback: proc()) {
  append(&systems.pause, System { -1, callback, time.now() })
}

systems_update :: proc() {
  timer.reset(timer.Type.SYSTEM)
  now := time.now()

  if game_state.paused {
    run_pause_systems(now)
  } else {
    run_runtime_systems(now)
  }
  
  run_internal_systems()

  timer.lock(timer.Type.SYSTEM)
}

@(private="file")
run_pause_systems :: proc(now: time.Time) {
  for &system in systems.pause {
    system.callback()
    system.last_updated_at = now
  }
}

@(private="file")
run_runtime_systems :: proc(now: time.Time) {
  for &system in systems.runtime {
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

@(private="file")
run_internal_systems :: proc() {
  if rl.IsKeyPressed(.ESCAPE) do game_state.paused = !game_state.paused
}

