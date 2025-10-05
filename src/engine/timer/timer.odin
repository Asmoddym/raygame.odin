package timer

import time_lib "core:time"

Type :: enum {
  SYSTEM,
  FRAME,
  TYPES,
}

Timer :: struct {
  time: time_lib.Time,
  elapsed: time_lib.Duration,
}

@(private="file")
timers: [Type.TYPES]Timer

reset :: proc(type: Type) {
  timers[type].time = time_lib.now()
}

lock :: proc(type: Type) {
  timers[type].elapsed = time_lib.diff(timers[type].time, time_lib.now())
}

as_milliseconds :: proc(type: Type) -> f64 {
  return time_lib.duration_milliseconds(timers[type].elapsed)
}
