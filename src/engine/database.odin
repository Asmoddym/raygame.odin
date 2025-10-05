package engine

import "error"

Table :: struct($ComponentType: typeid) {
  items: [dynamic]ComponentType,
}

database_add_component :: proc(entity_id: int, table: ^Table($ComponentType)) -> ^ComponentType {
  append(&table.items, ComponentType { })

  item := &table.items[len(table.items) - 1]
  item.base.entity_id = entity_id

  return item
}

database_get_component :: proc(
  entity_id: int,
  table: ^Table($ComponentType),
  desc: string = "",
  error_level: error.Level = error.Level.ERROR) -> ^ComponentType {
  for &c in table.items {
    if c.entity_id == entity_id {
      return &c
    }
  }

  // TODO: Better name this, as this exits too
  error.log(error_level, "No component type \"", desc, "\" for entity_id ", entity_id)

  return nil
}

database_create_entity :: proc() -> int {
  @(static) entity_count := 0

  id := entity_count
  entity_count += 1

  return id
}

