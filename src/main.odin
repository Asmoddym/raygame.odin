package macro

import "core:strings"
import "engine"
import rl "vendor:raylib"

s :: proc() {
  for t in table_textures.items {
    rl.DrawText(strings.unsafe_string_to_cstring(t.key), 100, 100, 20, rl.RED)
  }
}

main :: proc() {
  engine.init()
  engine.init_table(&table_textures)
  engine.register_system(s)

  eid := engine.create_entity()
  engine.add_component(eid, &table_textures).key = "coucou"

  engine.run()
}

