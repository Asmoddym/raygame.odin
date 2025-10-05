package macro

import "core:strings"
import "engine"

import rl "vendor:raylib"

s :: proc() {
  for eid in engine.database.entity_ids {
    t:= engine.database_get_component(eid, &table_textures)

    if t != nil {
      rl.DrawText(strings.unsafe_string_to_cstring(t.key), 100, 100, 20, rl.RED)
      t.key = strings.concatenate({t.key, "a"})
    }
  }
}

main :: proc() {
  engine.init()
  engine.database_init_table(&table_textures)
  engine.systems_register(s)

  eid := engine.database_create_entity()
  engine.database_add_component(eid, &table_textures).key = "coucou"

  engine.run()
}
