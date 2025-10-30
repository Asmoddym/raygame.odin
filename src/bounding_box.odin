package macro

import "engine"
import "enums"
import "core:slice"
import "core:math"
import rl "vendor:raylib"


// COMPONENTS DEFINITION


Component_BoundingBox :: struct {
  using base: engine.Component(engine.Metadata),

  box: rl.Rectangle,
  collidable: bool,
  movable: bool,
}

table_bounding_boxes: [5]engine.Table(Component_BoundingBox)



//
// SYSTEMS
//



// Main collision system using bounding_box components
// Sort & sweep implementation from https://leanrada.com/notes/sweep-and-prune/
bounding_box_system_collision_resolver :: proc() {
  for layer in 0..<5 {
    x_points: [dynamic]EdgeData
    x_active_intervals: [dynamic]int

    bounding_box_table := &table_bounding_boxes[layer]

    for bounding_box in bounding_box_table.items {
      if !bounding_box.collidable do continue

      box := bounding_box.box
      entity_id := bounding_box.entity_id

      append(&x_points, EdgeData { entity_id, box.x, 0 })
      append(&x_points, EdgeData { entity_id, box.x + box.width, 1 })
    }

    slice.sort_by(x_points[:], proc(i, j: EdgeData) -> bool { return i.v < j.v })

    for x in x_points {
      if x.type == 0 {
        entity_id := x.id

        for other_entity_id in x_active_intervals {
          resolve_collision(entity_id, other_entity_id, layer)
        }

        append(&x_active_intervals, x.id)
      } else {
        remove_by_id(&x_active_intervals, x.id)
      }
    }
  }
}

// Draw bounds if activated
bounding_box_system_draw :: proc() {
  if rl.IsKeyPressed(.B) do show_bounds = !show_bounds

  if !show_bounds do return

  for layer in 0..<5 {
    color := rl.Color { 0, 255 / u8(layer + 1), 50 * u8(layer + 1), 255 }

    for &bounding_box in table_bounding_boxes[layer].items {
      box := &bounding_box.box

      if !bounding_box.collidable {
        if show_bounds do rl.DrawRectangleLinesEx(box^, 1, rl.Color { 130, 130, 130, 255 / u8(layer + 1) })

          continue
      }

      rl.DrawRectangleLinesEx(box^, 2, color)

      if !bounding_box.movable {
        rl.DrawLineEx(rl.Vector2 { box.x, box.y }, rl.Vector2 { box.x + box.width, box.y + box.height }, 2, color)
        rl.DrawLineEx(rl.Vector2 { box.x + box.width, box.y }, rl.Vector2 { box.x, box.y + box.height }, 2, color)
      }
    }
  }
}



//
// PRIVATE
//



@(private="file")
EdgeData :: struct {
  id: int,
  v: f32,
  type: int,
}

@(private="file")
compass := #partial [enums.Direction]rl.Vector2 {
  .UP = rl.Vector2 { 0, 1 },
  .RIGHT = rl.Vector2 { 1, 0 },
  .DOWN = rl.Vector2 { 0, -1 },
  .LEFT = rl.Vector2 { -1, 0 },
}

@(private="file")
show_bounds := true


// Collision resolver
@(private="file")
resolve_collision :: proc(entity_id: int, other_entity_id: int, layer: int) {
  bounding_box := engine.database_get_component(entity_id, &table_bounding_boxes[layer])
  other_bounding_box := engine.database_get_component(other_entity_id, &table_bounding_boxes[layer])

  box := &bounding_box.box
  other_box := &other_bounding_box.box

  if !rl.CheckCollisionRecs(box^, other_box^) do return

  rectangle_center := calculate_center(box^)
  other_rectangle_center := calculate_center(other_box^)

  diff := rl.Vector2 { rectangle_center.x - other_rectangle_center.x, rectangle_center.y - other_rectangle_center.y }
  normalized := normalize(diff)
  collision_rec := rl.GetCollisionRec(box^, other_box^)

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
    diff := collision_rec.width / 2

    // As the algorithm begins with X coord, we know box will always be the entity at the right.

    if bounding_box.movable do box.x += diff
    if other_bounding_box.movable do other_box.x -= diff
  } else {
    diff := collision_rec.height / 2

    // Here, we need to check in which direction the collision occurred
    diff *= best_match == .UP ? 1 : -1

    if bounding_box.movable do box.y += diff
    if other_bounding_box.movable do other_box.y -= diff
  }

  if show_bounds {
    rl.DrawRectangleLinesEx(other_box^, 1, rl.YELLOW)
    rl.DrawRectangleRec(collision_rec, rl.RED)
  }
}


// Utils


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
