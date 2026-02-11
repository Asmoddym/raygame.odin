package engine

import rl "vendor:raylib"
import "utl"


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
  id: int,
  resolution: [2]i32,
  render_texture: rl.RenderTexture,
  dimension_ratios: [2]f32,
  position_hook: [2]f32,
  position: [2]f32,
  on_init: proc(o: ^Overlay),
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


// Create an overlay and store it in a scene, with its and resolution ratio and position position_hook.
scene_overlay_create_with_ratios :: proc(#any_int scene_id: int, #any_int overlay_id: int, dimension_ratios: [2]f32, position_hook: [2]f32, on_init: proc(overlay: ^Overlay) = nil) {
  scene      := &scene_registry[scene_id]
  resolution := overlay_calculate_resolution(dimension_ratios)

  scene.overlays[overlay_id] = Overlay {
    overlay_id,
    resolution,
    rl.LoadRenderTexture(i32(resolution.x), i32(resolution.y)),
    dimension_ratios,
    position_hook,
    utl.position_calculate(position_hook, game_state.resolution, resolution),
    on_init,
  }
  if on_init != nil do on_init(&scene.overlays[overlay_id])
}

// Create an overlay and store it in a scene, with its position hook and a unique ratio based on width.
scene_overlay_create_with_width_ratio :: proc(#any_int scene_id: int, #any_int overlay_id: int, width_ratio: f32, position_hook: [2]f32, on_init: proc(overlay: ^Overlay) = nil) {
  resolution: [2]f32 = {
    f32(game_state.resolution.x) * width_ratio,
    f32(game_state.resolution.x) * width_ratio,
  }

  dimension_ratios: [2]f32 = {
    resolution.x / f32(game_state.resolution.x),
    resolution.y / f32(game_state.resolution.y),
  }

  scene_overlay_create_with_ratios(scene_id, overlay_id, dimension_ratios, position_hook, on_init)
}

// scene_overlay_create union
scene_overlay_create :: proc {
scene_overlay_create_with_ratios,
scene_overlay_create_with_width_ratio,
}

// Draw a scene overlay.
// Clears the render textures and draws stuff from the given callback.
scene_overlay_draw :: proc(#any_int overlay_id: int, callback: proc(overlay: ^Overlay)) {
  overlay := &game_state.current_scene.overlays[overlay_id]

  rl.BeginTextureMode(overlay.render_texture)
  rl.ClearBackground(rl.BLACK)
  callback(overlay)

  rl.DrawRectangleLines(1, 1, i32(overlay.resolution.x - 1), i32(overlay.resolution.y - 2), rl.WHITE)
  rl.EndTextureMode()

  rl.DrawTexturePro(overlay.render_texture.texture,
    rl.Rectangle { 0, 0, f32(overlay.resolution.x), -f32(overlay.resolution.y) },
    rl.Rectangle { overlay.position.x, overlay.position.y, f32(overlay.resolution.x), f32(overlay.resolution.y) },
    rl.Vector2 { 0, 0 }, 0, rl.WHITE)
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
      overlay.resolution = overlay_calculate_resolution(overlay.dimension_ratios)
      overlay.position = utl.position_calculate(overlay.position_hook, game_state.resolution, overlay.resolution)

      rl.UnloadRenderTexture(overlay.render_texture)

      overlay.render_texture = rl.LoadRenderTexture(i32(overlay.resolution.x), i32(overlay.resolution.y))
      if overlay.on_init != nil do overlay.on_init(overlay)
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
@(private="file")
overlay_calculate_resolution :: proc(dimension_ratios: [2]f32) -> [2]i32 {
 return {
    i32(f32(game_state.resolution.x) * dimension_ratios[0]),
    i32(f32(game_state.resolution.y) * dimension_ratios[1]),
  }
}
