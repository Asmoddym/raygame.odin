package engine

import rl "vendor:raylib"



//
// PUBLIC API
//



// Create an overlay with its render texture and resolution.
overlay_create :: proc(resolution_ratio: [2]i32, blocking: bool = false) {
  @(static) counter := 0

  resolution: [2]i32 = {
    game_state.resolution.x * resolution_ratio.x,
    game_state.resolution.y * resolution_ratio.y,
  }

  append(&overlays, Overlay {
    rl.LoadRenderTexture(resolution.x, resolution.y),
    resolution_ratio,
    blocking,
    resolution,
    counter,
  })

  counter += 1
}

// Update overlays after a resolution change
overlay_update_resolutions :: proc() {
  for &overlay in overlays {
    resolution: [2]i32 = {
      game_state.resolution.x * overlay.resolution_ratio.x,
      game_state.resolution.y * overlay.resolution_ratio.y,
    }

    rl.UnloadRenderTexture(overlay.render_texture)

    overlay.resolution = resolution
    overlay.render_texture = rl.LoadRenderTexture(resolution.x, resolution.y)
  }
}



//
// PRIVATE
//



// Overlays storage
@(private="file")
overlays: [dynamic]Overlay

// Overlay data type handling render texture, resolution and init state
@(private="file")
Overlay :: struct {
  render_texture: rl.RenderTexture,
  resolution_ratio: [2]i32,
  blocking: bool,

  // Internal
  resolution: [2]i32,
  id: int,
}
