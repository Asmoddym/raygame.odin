package macro

import "engine"

Component :: struct {
  id: int,
  eid: int,

  variant: Component_Variants,
}

// ------

Component_Variants :: union {
  ^Component_Texture,
}

Component_Texture :: struct {
  using base: Component,

  key: string,
}

table_textures: engine.Table(Component_Texture)
