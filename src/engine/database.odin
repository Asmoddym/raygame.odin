package engine

import "error"

Table :: struct($ComponentType: typeid) {
  items: [dynamic]ComponentType,
}

database_add_component :: proc(eid: int, table: ^Table($ComponentType)) -> ^ComponentType {
  append(&table.items, ComponentType { })

  item := &table.items[len(table.items) - 1]
  item.base.eid = eid

  return item
}

database_get_component :: proc(
  eid: int,
  table: ^Table($ComponentType),
  desc: string = "",
  error_level: error.Level = error.Level.ERROR) -> ^ComponentType {
  for &c in table.items {
    if c.eid == eid {
      return &c
    }
  }

  error.log(error_level, "No component type \"", desc, "\" for eid ", eid)

  return nil
}

database_create_entity :: proc() -> int {
  @(static) entity_count := 0

  id := entity_count
  entity_count += 1

  return id
}

