package macro

import "terrain"
import rl "vendor:raylib"


// SYSTEMS


game_update_resources :: proc() {
  _game.resources.wood += 1

  delta := rl.GetMouseDelta()

  if delta.x != 0 || delta.y != 0 {
    coords := terrain.get_current_hovered_cell_coords()

    terrain.discover_circular_part(coords, 7)
  }
}



// PRIVATE



// TYPEDEF


// Resources counter
@(private="file")
Resources :: struct {
  gold: int,
  wood: int,
  stone: int,
}

// Main game data struct
@(private="file")
Game :: struct {
  resources: Resources,
}



// GLOBALS



_game: Game = {
  { 0, 0, 0 },
}

