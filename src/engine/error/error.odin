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
  case Level.WARN:
    __log("WARN", ..args)
  case Level.NONE:
  }
}

raise :: proc(args: ..any) {
  log(.ERROR, ..args)
  os.exit(1)
}

@(private="file")
__log :: proc(prefix: string, args: ..any) {
  fmt.eprint("[", prefix, "] ", sep = "")
  fmt.eprintln(..args, sep = "")
}

