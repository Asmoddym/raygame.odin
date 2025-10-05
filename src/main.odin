package macro

import "core:fmt"
import unicode "core:unicode/utf8"
import "core:strings"
import "engine"

import rl "vendor:raylib"

draw :: proc() {
  // for eid in engine.database.entity_ids {
  //   t:= engine.database_get_component(eid, &table_textures)
  //
  //   if t != nil {
  //     rl.DrawText(strings.unsafe_string_to_cstring(t.key), 100, 100, 20, rl.RED)
  //     t.key = strings.concatenate({t.key, "a"})
  //   }
  // }

  for t in table_textures.items {
    rl.DrawText(strings.unsafe_string_to_cstring(t.key), 100, 100, 20, rl.RED)
  }
}

update_text :: proc() {
  @(static) c := 0

  c+= 1

  for &t in table_textures.items {
    t.key = strings.concatenate({t.key, fmt.tprintf("\n%d. ", c)})
  }
}

input :: proc() {
  t := &table_textures.items[0]
  c: rune
  process_key: bool = true

  for process_key {
    c = rl.GetCharPressed()
    process_key = c != 0

    if process_key {
      t.key = strings.concatenate({t.key, unicode.runes_to_string({c})})
    }
  }
}

main :: proc() {
  engine.init()
  engine.database_init_table(&table_textures)

  engine.systems_register(draw)
  engine.systems_register(update_text, recurrence_in_ms = 500)

  engine.systems_register(input)

  eid := engine.database_create_entity()
  engine.database_add_component(eid, &table_textures).key = "coucou"

  engine.run()
}
