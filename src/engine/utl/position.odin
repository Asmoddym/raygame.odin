package utl

position_calculate :: proc(hook: PositionHook, screen_resolution, item_resolution: [2]i32) -> [2]f32 {
  position: [2]i32

  #partial switch hook {
  case .CENTER:
    position = {
      screen_resolution.x / 2 - item_resolution.x / 2,
      screen_resolution.y / 2 - item_resolution.y / 2,
    }

    break
  case .UP_LEFT:
    position = { 5, 5 }

    break
  case .DOWN_RIGHT:
    position = {
      screen_resolution.x - item_resolution.x - 5,
      screen_resolution.y - item_resolution.y - 5,
    }

    break
  }

  return { f32(position.x), f32(position.y) }
}

PositionHook :: enum {
  CENTER,
  UP_LEFT,
  DOWN_RIGHT,
  POSITIONS,
}
