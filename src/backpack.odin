package macro

import "engine"
import "enums"


// WIP: Backpack component. Will hold inventory for entities having one, not necessarily the player.
Component_Backpack :: struct {
  using base: engine.Component(engine.Metadata),

  max_items: int,
  items: [dynamic]enums.ItemID,
}

table_backpacks: engine.Table(Component_Backpack)

