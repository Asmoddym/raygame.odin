package engine

import "core:fmt"
import rl "vendor:raylib"


assets_find_or_create :: proc($Type: typeid, args: ..any) -> Type {
  if Type == rl.Texture2D {
    cstring := fmt.ctprint(..args)
    identifier := string(cstring)

    found_item := assets_find_in(&textures, identifier)
    if found_item != nil do return found_item.value

    append(&textures, Item(rl.Texture2D) { identifier, rl.LoadTexture(cstring) })

    return textures[len(textures) - 1].value
  }

  assert(false, fmt.tprint("assets_find_or_create: unable to store with args ", args))
  return Type {}
}



//
// INTERNAL API
//



// Unload all stored data when exiting the program. Called from application::unload
@(private="package")
assets_unload :: proc() {
  for &item in textures {
    rl.UnloadTexture(item.value)
  }
}



//
// PRIVATE
//



// Simple item struct with a string identifier:
// For textures, it's the file path
// For the rest, we'll see
@(private="file")
Item :: struct($T: typeid) {
  identifier: string,
  value: T,
}

// Texture storing
@(private="file")
textures: [dynamic]Item(rl.Texture2D)


// Find an element in a storage array
assets_find_in :: proc(array: ^[dynamic]Item($Type), identifier: string) -> ^Item(Type) {
  for &item in array {
    if item.identifier == identifier do return &item
  }

  return nil
}
