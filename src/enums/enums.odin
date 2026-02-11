package enums

// Player direction
Direction :: enum {
  NONE = -1,
  LEFT,
  RIGHT,
  UP,
  DOWN,
  DIRECTIONS,
}

// Scene IDs
SceneID :: enum {
  MAIN,
  PAUSE,
}

// Overlay IDs
OverlayID :: enum {
  CONTROLS,
  MINIMAP,
}

// Items
ItemID :: enum {
  NONE = 0,
  FLOWER,
}
