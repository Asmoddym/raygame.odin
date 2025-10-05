package engine

import "error"

Database :: struct {
  entity_ids: [dynamic]int,
}

Table :: struct($ComponentType: typeid) {
  count: int,
  items: [dynamic]ComponentType,
}

database: Database

// -----

database_init_table :: proc(table: ^Table($ComponentType)) {
  table.count = 0
}

database_add_component :: proc(eid: int, table: ^Table($ComponentType)) -> ^ComponentType {
  append(&table.items, ComponentType { })

  item := &table.items[len(table.items) - 1]

  item.base.id = table.count
  item.base.eid = eid

  table.count += 1
  return item
}

database_get_component :: proc(
  eid: int,
  table: ^Table($ComponentType),
  // init_callback: proc(eid: int, args: ..any) = proc(eid: int, args: ..any) {},
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
  append(&database.entity_ids, id)
  entity_count += 1

  return id
}

