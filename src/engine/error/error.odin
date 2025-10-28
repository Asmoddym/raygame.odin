package error

import "core:os"
import "core:fmt"


// Log level enum
Level :: enum {
  ERROR,
  WARN,
  NONE,
}


// Log a message on the given level
log :: proc(level: Level, args: ..any) {
  switch level {
  case Level.ERROR:
    __log("ERROR", ..args)
  case Level.WARN:
    __log("WARN", ..args)
  case Level.NONE:
  }
}

// Log an error and force-exit the program
raise :: proc(args: ..any) {
  log(.ERROR, ..args)
  os.exit(1)
}



//
// PRIVATE
//



@(private="file")
__log :: proc(prefix: string, args: ..any) {
  fmt.eprint("[", prefix, "] ", sep = "")
  fmt.eprintln(..args, sep = "")
}

