package engine


//
// PUBLIC API
//


scene_registry: map[int]Scene


scene_create :: proc(id: int, uses_camera: bool, blocking: bool = false) {
  scene_registry[id] = Scene {
    uses_camera,
    blocking,
    id,
  }
}

scene_set_current :: proc(id: int) {
  game_state.current_scene = &scene_registry[id]
}



//
// PRIVATE
//



Scene :: struct {
  uses_camera: bool,
  blocking: bool,

  // Internal
  id: int,
}
