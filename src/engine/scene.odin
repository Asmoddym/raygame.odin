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
  id: int,
  resolution: [2]f32,
  render_texture: rl.RenderTexture,
  dimension_ratios: [2]f32,
  position_hook: Position,
  position: [2]f32,
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


// Create an overlay and store it in a scene, with its render texture and resolution ratio.
scene_overlay_create_with_ratios :: proc(#any_int scene_id: int, #any_int overlay_id: int, dimension_ratios: [2]f32, position_hook: Position) {
  scene := &scene_registry[scene_id]
  resolution: [2]f32

  resolution = overlay_calculate_resolution(dimension_ratios)

  scene.overlays[overlay_id] = Overlay {
    overlay_id,
    resolution,
    rl.LoadRenderTexture(i32(resolution.x), i32(resolution.y)),
    dimension_ratios,
    position_hook,
    { 0, 0 },
  }

  value, ok := &scene.overlays[overlay_id]
  value.position = overlay_calculate_position(&scene.overlays[overlay_id])
}

// Create an overlay and store it in a scene, with its render texture and a unique ratio based on width.
scene_overlay_create_with_width_ratio :: proc(#any_int scene_id: int, #any_int overlay_id: int, width_ratio: f32, position: Position) {
  resolution: [2]f32 = {
    f32(game_state.resolution.x) * width_ratio,
    f32(game_state.resolution.x) * width_ratio,
  }

  dimension_ratios: [2]f32 = {
    resolution.x / f32(game_state.resolution.x),
    resolution.y / f32(game_state.resolution.y),
  }

  scene_overlay_create_with_ratios(scene_id, overlay_id, dimension_ratios, position)
}

scene_overlay_create :: proc {
scene_overlay_create_with_ratios,
scene_overlay_create_with_width_ratio,
}

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
      resolution := overlay_calculate_resolution(overlay.dimension_ratios)

      rl.UnloadRenderTexture(overlay.render_texture)

      overlay.resolution = resolution
      overlay.render_texture = rl.LoadRenderTexture(i32(resolution.x), i32(resolution.y))
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
overlay_calculate_resolution :: proc(dimension_ratios: [2]f32) -> [2]f32 {
 return {
    f32(game_state.resolution.x) * dimension_ratios[0],
    f32(game_state.resolution.y) * dimension_ratios[1],
  }
}

overlay_calculate_position :: proc(overlay: ^Overlay) -> [2]f32 {
  position: [2]f32

  #partial switch overlay.position_hook {
  case .CENTER:
    position = {
      f32(game_state.resolution.x) / 2 - overlay.resolution.x / 2,
      f32(game_state.resolution.y) / 2 - overlay.resolution.y / 2,
    }

    break
  case .UP_LEFT:
    position = { 5, 5 }

    break
  case .DOWN_RIGHT:
    position = {
      f32(game_state.resolution.x) - overlay.resolution.x - 5,
      f32(game_state.resolution.y) - overlay.resolution.y - 5,
    }

    break
  }

  return position
}

Position :: enum {
  CENTER,
  UP_LEFT,
  DOWN_RIGHT,
  POSITIONS,
}
