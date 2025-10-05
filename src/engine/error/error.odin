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
     fmt.eprint("[ERROR] ")
     fmt.eprintln(..args, sep = "")
     os.exit(1)
  case Level.WARN:
    when ODIN_DEBUG {
      fmt.eprint("[WARN] ")
      fmt.eprintln(..args, sep = "")
    }
  case Level.NONE:
  }
}

