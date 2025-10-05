package error

import "core:os"
import "core:fmt"

Level :: enum {
  ERROR,
  WARN,
  NONE,
}

log :: proc(level: Level, args: ..any) {
  switch level {
  case Level.ERROR:
    __log("ERROR", ..args)
     os.exit(1)
  case Level.WARN:
    when ODIN_DEBUG {
    __log("WARN", ..args)
    }
  case Level.NONE:
  }
}

@(private="file")
__log :: proc(prefix: string, args: ..any) {
  fmt.eprint("[", prefix, "] ", sep = "")
  fmt.eprintln(..args, sep = "")
}

