package engine

import "utl/timer"

// -----
// Systems management
// -----

@(private="file")
systems: [dynamic]proc()

systems_register :: proc(callback: proc()) {
  append(&systems, callback)
}

systems_update :: proc() {
  timer.reset(timer.Type.SYSTEM)
  for system in systems {
    system()
  }
  timer.lock(timer.Type.SYSTEM)
}

