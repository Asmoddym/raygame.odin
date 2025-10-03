package main

import "core:fmt"

import rl "vendor:raylib"

DEBUG::#config(DEBUG, false)


Table :: struct($K: typeid) {
  key: K
}

Table2 :: struct($K: typeid) {
  key: K
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

main::proc() {
  i: int = 1

  b: proc(int) = proc(i: int) { fmt.println(i) }

  a:= create_table("coucou")
  fmt.println("> ", a.key)
  bla2(a, "bla")
  fmt.println(">> ", a.key)


  when DEBUG {
    coucou(&i, coucou = 3)
    b(i)
  }

  rl.InitWindow(10, 10, "coucou")

  for !rl.WindowShouldClose() {
    rl.BeginDrawing()
    rl.ClearBackground(rl.RED)
    rl.EndDrawing()
  }

  rl.CloseWindow()

}
