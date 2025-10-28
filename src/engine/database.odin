package engine

import "error"


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
// Optional: description, can be set to provide more information if no component is found
database_get_component :: proc(entity_id: int, table: ^Table($ComponentType), desc: string = "") -> ^ComponentType {
  for &c in table.items {
    if c.entity_id == entity_id {
      return &c
    }
  }

  error.raise("No component type \"", desc, "\" for entity_id ", entity_id)

  return nil
}

// Check if a component exists in the table address by its entity_id
database_has_component :: proc(entity_id: int, table: ^Table($ComponentType)) -> bool {
  for &c in table.items {
    if c.entity_id == entity_id {
      return true
    }
  }

  return false
}

