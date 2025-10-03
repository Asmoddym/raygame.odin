package main

import "core:mem"
import "core:fmt"
import rl "vendor:raylib"

DEBUG::#config(DEBUG, false)

Table :: struct($K: typeid) {
  key: K,
}

Table2 :: struct($K: typeid) {
  key: K,
}

create_table::proc(v: $K) -> ^Table(K) {
  a:= new(Table(K))
  a.key = v

  return a
}

bla2::proc(a: ^$T/Table($K), key: K) {
  a^.key = key
}

coucou::proc(i: ^int, coucou:int) {
  fmt.println("%d a", 1, "a", sep = "a")
  i^ += 1
}

bloup::proc() {
  a:= create_table("coucou")
  fmt.println("> ", a.key)
  bla2(a, "bla")
  fmt.println(">> ", a.key)

  free(a)

  when DEBUG {
    coucou(&i, coucou = 3)
    b(i)
  }

  rl.ChangeDirectory("resources")
  rl.SetConfigFlags({rl.ConfigFlag.VSYNC_HINT, rl.ConfigFlag.WINDOW_HIGHDPI})

  rl.InitWindow(1000, 1000, "coucou")

  texture: rl.Texture = rl.LoadTexture("cursor1.png")

  for !rl.WindowShouldClose() {
    rl.BeginDrawing()
    rl.DrawText(fmt.ctprint(rl.GetFPS()), 0, 0, 20, rl.WHITE)
    rl.DrawText(rl.GetWorkingDirectory(), 100, 100, 20, rl.WHITE)
    rl.DrawTexture(texture, 10, 10, rl.WHITE)
    rl.ClearBackground(rl.RED)
    rl.EndDrawing()
  }


  rl.CloseWindow()

  // rl.UnloadTexture(texture)
}

main::proc() {
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

  bloup()
}
