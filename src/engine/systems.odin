package engine

import "core:slice"
import "core:time"


// Register a system from its type and callback.
// Optional: recurrence_in_ms, defaulting to -1 to run each frame
system_register :: proc(callback: proc(), scene_ids: []int = {}, recurrence_in_ms: f64 = -1) {
  append(&system_registry, System { recurrence_in_ms, scene_ids, slice.length(scene_ids) == 0, callback, time.now() })
}



//
// INTERNAL API
//



// Main entrypoint for systems update backend-side
systems_update :: proc(current_scene_id: int, now: time.Time) {
  for &system in system_registry {
    if can_update(&system, current_scene_id, now) {
      system.callback()
      system.last_updated_at = now
    }
  }
}



//
// PRIVATE
//



// Main registry
@(private="file")
system_registry: [dynamic]System

// System typedef
@(private="file")
System :: struct {
  recurrence_in_ms: f64,
  scene_ids: []int,
  run_for_all_scenes: bool,
  callback: proc(),
  last_updated_at: time.Time,
}


// Misc


// Check if recurrence is verified for a system
@(private="file")
can_update :: proc(system: ^System, current_scene_id: int, now: time.Time) -> bool {
  context.user_index = current_scene_id

  if !system.run_for_all_scenes && !slice.any_of_proc(system.scene_ids, proc(id: int) -> bool { return id == context.user_index }) {
    return false
  }

  return time.duration_milliseconds(time.diff(system.last_updated_at, now)) > system.recurrence_in_ms
}
