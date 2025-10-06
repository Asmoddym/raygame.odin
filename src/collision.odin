#+feature dynamic-literals

package macro

import rl "vendor:raylib"
import "core:slice"
import "engine"
import "core:math"
import "enums"

@(private="file")
show_bounds := false

@(private="file")
EdgeData :: struct {
  id: int,
  v: f32,
  type: int,
}

@(private="file")
compass := #partial [enums.Direction]rl.Vector2 {
  .UP = rl.Vector2 { 0, 1 }, // up
  .RIGHT = rl.Vector2 { 1, 0 }, // right
  .DOWN = rl.Vector2 { 0, -1 }, // down
  .LEFT = rl.Vector2 { -1, 0 }, // left
}

collision_system :: proc() {
  if rl.IsKeyPressed(.B) do show_bounds = !show_bounds

  x_points: [dynamic]EdgeData
  x_active_intervals: [dynamic]int

  for dimensions in table_dimensions.items {
    entity_id := dimensions.entity_id
    position := engine.database_get_component(entity_id, &table_positions)

    rect := rl.Rectangle { f32(position.x), f32(position.y), f32(dimensions.width), f32(dimensions.height) }

    append(&x_points, EdgeData { entity_id, rect.x, 0 })
    append(&x_points, EdgeData { entity_id, rect.x + rect.width, 1 })
  }

  // Sort & sweep implementation from https://leanrada.com/notes/sweep-and-prune/

  slice.sort_by(x_points[:], proc(i, j: EdgeData) -> bool { return i.v < j.v })

  for x in x_points {
    if x.type == 0 {
      entity_id := x.id

      for other_entity_id in x_active_intervals {
        resolve_collision(entity_id, other_entity_id)
      }

      append(&x_active_intervals, x.id)
    } else {
      remove_by_id(&x_active_intervals, x.id)
    }
  }
}

@(private="file")
resolve_collision :: proc(entity_id: int, other_entity_id: int) {
  position := engine.database_get_component(entity_id, &table_positions)
  other_position := engine.database_get_component(other_entity_id, &table_positions)
  dimensions := engine.database_get_component(entity_id, &table_dimensions)
  other_dimensions := engine.database_get_component(other_entity_id, &table_dimensions)

  rectangle := rl.Rectangle { f32(position.x), f32(position.y), f32(dimensions.width), f32(dimensions.height) }
  other_rectangle := rl.Rectangle { f32(other_position.x) , f32(other_position.y) , f32(other_dimensions.width) , f32(other_dimensions.height) }

  if !rl.CheckCollisionRecs(rectangle, other_rectangle) do return

  is_movable := engine.database_get_component(entity_id, &table_movables, error_level = .NONE) != nil
  other_is_movable := engine.database_get_component(other_entity_id, &table_movables, error_level = .NONE) != nil

  rectangle_center := calculate_center(rectangle)
  other_rectangle_center := calculate_center(other_rectangle)

  diff := rl.Vector2 { rectangle_center.x - other_rectangle_center.x, rectangle_center.y - other_rectangle_center.y }
  normalized := normalize(diff)
  collision_rec := rl.GetCollisionRec(rectangle, other_rectangle)

  // TODO: I should be able to remove left and/or right as I know there will be a X collision, and it should always be on the left (I think?)

  max: f32 = 0.0
  best_match: enums.Direction = .NONE

  for i in 0..<4 {
    di := enums.Direction(i)
    dot_product := normalized.x * compass[di].x + normalized.y * compass[di].y

    if dot_product > max {
      max = dot_product
      best_match = di
    }
  }

  if best_match == .LEFT || best_match == .RIGHT {
    mid_diff := collision_rec.width / 2

    // As the algorithm begins with X coord, we know rectangle will always be the entity at the right.
    if is_movable {
      position.x += int(mid_diff)
    }
    if other_is_movable {
      other_position.x -= int(mid_diff)
    }
  } else {
    mid_diff := collision_rec.height / 2

    // Here, we need to check in which direction the collision occurred
    mid_diff *= best_match == .UP ? 1 : -1

    if is_movable {
      position.y += int(mid_diff)
    }
    if other_is_movable {
      other_position.y -= int(mid_diff)
    }
  }

  if show_bounds {
    rl.DrawRectangleLinesEx(rectangle, 1, is_movable ? rl.GREEN : rl.BLUE)
    rl.DrawRectangleLinesEx(other_rectangle, 1, other_is_movable ? rl.YELLOW : rl.BLUE)
    rl.DrawRectangleRec(collision_rec, rl.RED)
  }
}

@(private="file")
calculate_center :: proc(rect: rl.Rectangle) -> rl.Vector2 {
  rect_half_extents := rl.Vector2 { rect.width / 2, rect.height / 2 }

  return { rect.x + rect_half_extents.x, rect.y + rect_half_extents.y }
}

@(private="file")
normalize :: proc(v: rl.Vector2) -> rl.Vector2 {
  length_of_v := math.sqrt((v.x * v.x) + (v.y * v.y))

  return rl.Vector2 { v.x / length_of_v, v.y / length_of_v }
}

@(private="file")
remove_by_id :: proc(intervals: ^[dynamic]int, x: int) {
  for i := 0; i < len(intervals^); i += 1 {
    if intervals^[i] == x {
      ordered_remove(intervals, i)
      return
    }
  }
}
