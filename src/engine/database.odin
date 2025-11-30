package engine


// Metadata base class definition, designed to be inherited from if necessary
Metadata :: struct {}

// Main base component struct, simply storing entity_id and metadata class
Component :: struct($T: typeid) {
  entity_id: int,

  metadata: T,
}

// Table definition to allow component storage table instanciation
Table :: struct($ComponentType: typeid) {
  items: [dynamic]ComponentType,
}


// Create an entity (simply returns the incremented ID)
database_create_entity :: proc() -> int {
  @(static) entity_count := 0

  id := entity_count
  entity_count += 1

  return id
}

// Add a component and link it to an entity_id
database_add_component :: proc(entity_id: int, table: ^Table($ComponentType)) -> ^ComponentType {
  append(&table.items, ComponentType { })

  item := &table.items[len(table.items) - 1]
  item.base.entity_id = entity_id

  return item
}

// Destroy all components linked to entity_id
database_destroy_component :: proc(entity_id: int, table: ^Table($ComponentType)) {
  for i in 0..<len(table.items) {
    if table.items[i].entity_id == entity_id {
      unordered_remove(&(table^.items), i)
      return
    }
  }
}

// Get a component from its entity_id the component table address
database_get_component :: proc(entity_id: int, table: ^Table($ComponentType)) -> ^ComponentType {
  for &c in table.items {
    if c.entity_id == entity_id {
      return &c
    }
  }

  return nil
}
