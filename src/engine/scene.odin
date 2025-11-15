package engine


//
// PUBLIC API
//


scene_registry: map[int]Scene


scene_create :: proc(#any_int id: int, uses_camera: bool) {
  scene_registry[id] = Scene {
    uses_camera,
    id,
  }
}

scene_set_current :: proc(#any_int id: int) {
  game_state.current_scene = &scene_registry[id]
}



//
// PRIVATE
//



Scene :: struct {
  uses_camera: bool,

  // Internal
  id: int,
}
