package macro
//
// import "core:fmt"
// import "core:strings"
// import "engine"
// import rl "vendor:raylib"
//
// //
// // // Overlay type and declaration, public to be checked in input system for example
// // OverlayType :: enum {
// //   PAUSE,
// //   MENU,
// //   NONE,
// // }
// //
// // pause_current: OverlayType = .NONE
// //
//
//
// //
// // SYSTEMS
// //
//
//
//
// //
// // PRIVATE
// //
//
//
//
// @(private="file")
// INVENTORY_LINE_HEIGHT_RATIO := f32(0.1)
//
// @(private="file")
// INVENTORY_LINE_WIDTH_RATIO := f32(0.5)
//
//
// // Pause subsystem, considered blocking
// @(private="file")
// pause_subsystem_pause :: proc() {
// }
//
// // Inventory line
// @(private="file")
// pause_subsystem_inventory_line :: proc() {
//   // height := i32(f32(engine.game_state.resolution.y) * INVENTORY_LINE_HEIGHT_RATIO)
//   // width := i32(f32(engine.game_state.resolution.x) * INVENTORY_LINE_WIDTH_RATIO)
//   //
//   // position: [2]i32 = { (engine.game_state.resolution.x / 2 - width / 2), (engine.game_state.resolution.y - height) }
//   //
//   // rl.DrawRectangle(position.x, position.y, width, height, rl.WHITE)
// }
//
// // Menu subsystem, considered non-blocking
// @(private="file")
// pause_subsystem_menu :: proc() {
//   // overlay := &engine.game_state.overlay
//   //
//   // // @(static) initialized := false
//   // //
//   // // if !initialized {
//   //   rl.BeginTextureMode(overlay.render_texture)
//   //   rl.ClearBackground(rl.BLACK)
//   //
//   //   // tiles: i32 = 4
//   //   // margin: i32 = overlay.resolution.x / 50
//   //   // square_size := f32((overlay.resolution.x - ((tiles + 1) * margin)) / tiles)
//   //   //
//   //   // for y in 0..<2 {
//   //   //   for x in 0..<tiles{
//   //   //     rl.DrawRectangleLinesEx(rl.Rectangle { f32(x) * square_size + f32(x + 1) * f32(margin),  f32(y) * square_size + f32(y + 1) * f32(margin), square_size, square_size }, 2, rl.WHITE)
//   //   //
//   //   //     rl.DrawText(fmt.ctprint(x + 1, ", ", y + 1), i32(x) * i32(square_size) + i32(x + 1) * margin, i32(y) * i32(square_size) + i32(y + 1) * margin, 20, rl.WHITE)
//   //   //   }
//   //   // }
//   //   //
//   //
//   //   //
//   //   // rl.DrawText(strings.unsafe_string_to_cstring("coucou"), 100, 200, 20, rl.WHITE)
//   //   //
//   //   // ui_button_draw_xy_centered_list(
//   //   //   { "MENU", "COUCOU" },
//   //   //   font_size = 40,
//   //   //   on_click = {
//   //   //     proc() { engine.game_state.closed = true },
//   //   //     proc() { engine.game_state.closed = true },
//   //   //   },
//   //   //   selected = selection,
//   //   //   resolution = overlay.resolution,
//   //   // )
//   //   rl.DrawText(strings.unsafe_string_to_cstring("MENU"), 100, 100, 30, rl.WHITE)
//   //   rl.EndTextureMode()
//   // //   initialized = true
//   // // }
//   //
//   //
//   // rl.DrawTexturePro(overlay.render_texture.texture,
//   //   rl.Rectangle { 0, 0, f32(overlay.resolution.x), -f32(overlay.resolution.y) },
//   //   rl.Rectangle { f32(engine.game_state.resolution.x - overlay.resolution.x) / 2, f32(engine.game_state.resolution.y - overlay.resolution.y) / 2, f32(overlay.resolution.x), f32(overlay.resolution.y) },
//   //   rl.Vector2 { 0, 0 }, 0, rl.WHITE)
//   //
//   // rl.DrawRectangleLinesEx(
//   //   rl.Rectangle {
//   //   f32((engine.game_state.resolution.x - overlay.resolution.x) / 2),
//   //   f32((engine.game_state.resolution.y - overlay.resolution.y) / 2),
//   //     f32(overlay.resolution.x),
//   //     f32(overlay.resolution.y),
//   //   }, 2, rl.WHITE,
//   // )
// }
//
