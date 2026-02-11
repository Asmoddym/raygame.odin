package utl

position_calculate :: proc(position_hook: [2]f32, container_resolution, item_resolution: [2]i32) -> [2]f32 {
  padding: f32 = 30

  container_resolution_with_offset: [2]f32 = {
    f32(container_resolution.x) - padding,
    f32(container_resolution.y) - padding,
  }

  position: [2]f32 = {
    padding / 2 + f32(container_resolution_with_offset.x) * position_hook.x - f32(item_resolution.x) / 2,
    padding / 2 + f32(container_resolution_with_offset.y) * position_hook.y - f32(item_resolution.y) / 2,
  }

  position.x = max(position.x, padding / 2)
  position.x = min(position.x, padding / 2 + container_resolution_with_offset.x - f32(item_resolution.x))
  position.y = max(padding / 2, position.y)
  position.y = min(position.y, padding / 2 + container_resolution_with_offset.y - f32(item_resolution.y))

  return position
}

PADDING: f32 = 30
