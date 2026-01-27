package macro


// SYSTEMS


game_update_resources :: proc() {
  _game.resources.wood += 1
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

