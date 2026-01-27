package engine

import "core:log"
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

// Overlay data type handling render texture, resolution and init state
Overlay :: struct {
  render_texture: rl.RenderTexture,
  width_ratio: f64,
  height_ratio: f64,

  // Internal
  resolution: [2]i32,
  id: int,
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
// TODO: Make 2 separate scene_overlay_create procs to handle this better than just passing 3 arguments
scene_overlay_create :: proc(#any_int scene_id: int, #any_int overlay_id: int, ratio: f64 = 0, width_ratio: f64 = 0, height_ratio: f64 = 0) {
  scene := &scene_registry[scene_id]
  resolution: [2]i32

  width_ratio := width_ratio
  height_ratio := height_ratio

  if ratio != 0 {
    // TODO: I could do this more cleanly by taking game_state.resolution ratio but it works, so...
    resolution = {
      i32(f64(game_state.resolution.x) * ratio),
      i32(f64(game_state.resolution.x) * ratio),
    }

    width_ratio = f64(resolution.x) / f64(game_state.resolution.x)
    height_ratio = f64(resolution.y) / f64(game_state.resolution.y)
  } else {
    resolution = calculate_resolution(width_ratio, height_ratio)
  }

  scene.overlays[overlay_id] = Overlay {
    rl.LoadRenderTexture(resolution.x, resolution.y),
    width_ratio,
    height_ratio,
    resolution,
    overlay_id,
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
      resolution := calculate_resolution(overlay.width_ratio, overlay.height_ratio)

      rl.UnloadRenderTexture(overlay.render_texture)

      overlay.resolution = resolution
      overlay.render_texture = rl.LoadRenderTexture(resolution.x, resolution.y)
    }
  }
}



//
// PRIVATE
//



// Scene registry by ID
@(private="file")
scene_registry: map[int]Scene

// Calculate resolution from a ratio
calculate_resolution :: proc(width_ratio: f64, height_ratio: f64) -> [2]i32 {
 return {
    i32(f64(game_state.resolution.x) * width_ratio),
    i32(f64(game_state.resolution.y) * height_ratio),
  }
}
