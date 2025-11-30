#+feature dynamic-literals
package macro

import "engine"
import "enums"
import rl "vendor:raylib"

Item :: struct {
  icon_path: cstring,
}

@(private="file")
item_registry: map[enums.ItemID]Item = {
  .FLOWER = { "grass_flower.png" },
}

items_get_icon :: proc(id: enums.ItemID) -> rl.Texture2D {
  return engine.assets_find_or_create(rl.Texture2D, item_registry[id].icon_path)
}
