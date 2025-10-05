package engine

import rl "vendor:raylib"
import "core:fmt"
import "core:strings"
import "timer"

DEBUG::#config(DEBUG, false)

// -----
// Registry and entity management
// -----

Table :: struct($ComponentType: typeid) {
  count: int,
  items: [dynamic]ComponentType,
}

init :: proc() {
  rl.SetConfigFlags({rl.ConfigFlag.VSYNC_HINT, rl.ConfigFlag.WINDOW_HIGHDPI})

  rl.InitWindow(1600, 900, "coucou")
}

create_entity :: proc() -> int {
  @(static) entity_count := 0

  id := entity_count
  entity_count += 1

  return id
}

init_table :: proc(table: ^Table($ComponentType)) {
  table.count = 0
}

add_component :: proc(eid: int, table: ^Table($ComponentType)) -> ^ComponentType {
  append(&table.items, ComponentType { })

  item := &table.items[len(table.items) - 1]

  item.base.id = table.count
  item.base.eid = eid

  table.count += 1
  return item
}

// -----
// Systems management
// -----

@(private="file")
systems: [dynamic]proc()

register_system :: proc(callback: proc()) {
  append(&systems, callback)
}

// -----
// Run
// -----

run :: proc() {
  for !rl.WindowShouldClose() {
    timer.reset(timer.Type.FRAME)

    rl.BeginDrawing()
    rl.ClearBackground(rl.BLACK)

    run_systems()

    timer.lock(timer.Type.FRAME)
    when ODIN_DEBUG {
      render_debug()
    }

    rl.EndDrawing()
  }
}

run_systems :: proc() {
  timer.reset(timer.Type.SYSTEM)
  for system in systems {
    system()
  }
  timer.lock(timer.Type.SYSTEM)
}

render_debug :: proc() {
  texts: [int(timer.Type.TYPES) + 1]string
  texts[0] = fmt.tprintf("%d FPS", rl.GetFPS())

  texts[1 + int(timer.Type.SYSTEM)] = fmt.tprintf("\nsystem : %.03fms", timer.as_milliseconds(timer.Type.SYSTEM))
  texts[1 + int(timer.Type.FRAME)]  = fmt.tprintf("\nframe  : %.03fms", timer.as_milliseconds(timer.Type.FRAME))

  str, err := strings.concatenate(texts[:])

  if err == nil {
    rl.DrawText(strings.unsafe_string_to_cstring(str), 10, 10, 20, rl.LIME)
  }
}

