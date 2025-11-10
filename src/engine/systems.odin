package engine

import "utl/timer"
import "core:time"


// System type definition.
// INTERNAL can be used to run systems regardless from the game state
SystemType :: enum {
  RUNTIME,
  OVERLAY,
  INTERNAL,
  SYSTEMS,
}


// Register a system from its type and callback.
// Optional: recurrence_in_ms, defaulting to -1 to run each frame
system_register :: proc(type: SystemType, callback: proc(), recurrence_in_ms: f64 = -1) {
  append(&system_registry[type], System { recurrence_in_ms, callback, time.now() })
}



//
// INTERNAL API
//



// Main entrypoint for systems update backend-side
systems_update :: proc() {
  timer.reset(timer.Type.SYSTEM)
  now := time.now()

  if game_state.in_overlay {
    run_systems(&system_registry[.OVERLAY], now)
  } else {
    run_systems(&system_registry[.RUNTIME], now)
  }

  run_systems(&system_registry[.INTERNAL], now)

  timer.lock(timer.Type.SYSTEM)
}



//
// PRIVATE
//



// Main registry
@(private="file")
system_registry: [SystemType][dynamic]System

// System typedef
@(private="file")
System :: struct {
  recurrence_in_ms: f64,
  callback: proc(),
  last_updated_at: time.Time,
}

// Generic system runner, taking a list and calling the callback for each
@(private="file")
run_systems :: proc(list: ^[dynamic]System, now: time.Time) {
  for &system in list {
    if can_update(&system, now) {
      system.callback()
      system.last_updated_at = now
    }
  }
}


// Misc


// Check if recurrence is verified for a system
@(private="file")
can_update :: proc(system: ^System, now: time.Time) -> bool {
  return time.duration_milliseconds(time.diff(system.last_updated_at, now)) > system.recurrence_in_ms
}
