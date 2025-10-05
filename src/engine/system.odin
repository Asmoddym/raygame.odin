package engine

import "core:time"
import "utl/timer"

System :: struct {
  recurrence_in_ms: f64,
  callback: proc(),
  last_updated_at: time.Time,
}

@(private="file")
systems: [dynamic]System

systems_register :: proc(callback: proc(), recurrence_in_ms: f64 = -1) {
  append(&systems, System { recurrence_in_ms, callback, time.now() })
}

systems_update :: proc() {
  timer.reset(timer.Type.SYSTEM)

  now := time.now()

  for &system in systems {
    if (systems_can_update(system, now)) {
      system.callback()
      system.last_updated_at = now
    }
  }

  timer.lock(timer.Type.SYSTEM)
}

systems_can_update :: proc(system: System, now: time.Time) -> bool {
  return time.duration_milliseconds(time.diff(system.last_updated_at, now)) > system.recurrence_in_ms
}
