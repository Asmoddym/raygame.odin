package timer

import time_lib "core:time"



//
// INTERNAL API
//



// Timer type enum
// SYSTEM: scopes all called systems
// FRAME: scopes all the frame, including systems
Type :: enum {
  SYSTEM,
  FRAME,
  TYPES,
}


// Reset a timer
reset :: proc(type: Type) {
  timers[type].time = time_lib.now()
}

// Lock a timer until the next reset() call
lock :: proc(type: Type) {
  timers[type].elapsed = time_lib.diff(timers[type].time, time_lib.now())
}

// Convert the timer to milliseconds
as_milliseconds :: proc(type: Type) -> f64 {
  return time_lib.duration_milliseconds(timers[type].elapsed)
}



//
// PRIVATE
//



// Main timer struct
@(private="file")
Timer :: struct {
  time: time_lib.Time,
  elapsed: time_lib.Duration,
}

// Timers store
@(private="file")
timers: [Type.TYPES]Timer

