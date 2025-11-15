package engine

import rl "vendor:raylib"


//
// PUBLIC API
//



// Scene definition
Scene :: struct {
  uses_camera: bool,

  // Internal
  id: int,
  overlays: map[int]Overlay,
}


// Create a scene from its ID
scene_create :: proc(#any_int id: int, uses_camera: bool) {
  scene_registry[id] = Scene {
    uses_camera,
    id,
    {},
  }
}

// Set the current scene from its ID
scene_set_current :: proc(#any_int id: int) {
  game_state.current_scene = &scene_registry[id]
}


// Create an overlay and store it in a scene, with its render texture and resolution.
scene_overlay_create :: proc(#any_int scene_id: int, #any_int overlay_id: int, width_ratio: f64 = -1, fixed_height: int = -1) {
  scene := &scene_registry[scene_id]
  resolution := calculate_resolution(width_ratio, fixed_height)

  scene.overlays[overlay_id] = Overlay {
    rl.LoadRenderTexture(resolution.x, resolution.y),
    width_ratio,
    fixed_height,
    resolution,
    overlay_id,
  }
}

calculate_resolution :: proc(width_ratio: f64, fixed_height: int) -> [2]i32 {
 return {
    i32(f64(game_state.resolution.x) * width_ratio),
    i32(fixed_height),
  }
}





//
// INTERNAL API
//



// Update overlays after a resolution change
scene_overlay_update_resolutions :: proc() {
  for scene_id in scene_registry {
    scene := &scene_registry[scene_id]

    for overlay_id in scene.overlays {
      overlay := &scene.overlays[overlay_id]
      resolution := calculate_resolution(overlay.width_ratio, overlay.fixed_height)

      rl.UnloadRenderTexture(overlay.render_texture)

      overlay.resolution = resolution
      overlay.render_texture = rl.LoadRenderTexture(resolution.x, resolution.y)
    }
  }
}



//
// PRIVATE
//



// Overlay data type handling render texture, resolution and init state
@(private="file")
Overlay :: struct {
  render_texture: rl.RenderTexture,
  width_ratio: f64,
  fixed_height: int,

  // Internal
  resolution: [2]i32,
  id: int,
}

// Scene registry by ID 
@(private="file")
scene_registry: map[int]Scene

