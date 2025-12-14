package perlin_noise

import "core:fmt"
import noise "core:math/noise"
import rand "core:math/rand"
import math "core:math"
import rl "vendor:raylib"

TerrainCell :: struct {
  altitude: f32,
  color: rl.Color,
  position: [2]int,
}

create_cell :: proc(y, x: int, altitude: f32) -> TerrainCell {
  color: rl.Color
  red, green, blue: u8 = 0, 0, 0

  // fmt.println("altitude: ", altitude)
  if altitude < -0.3 {
    blue = u8(math.remap_clamped(altitude, -0.9, 0, 0, 255))
    // color = rl.Color { 0, 0, u8(blue), 255 }
  }

  if altitude >= -0.3 && altitude < 0.3 {
    green = u8(math.remap_clamped(altitude, -0.3, 0.3, 50, 200))
  }

  if altitude >= 0.3 {
    red = u8(math.remap_clamped(altitude, 0.3, 0.9, 100, 255))
    green = red
    blue = red
  }
  // fmt.println(red, green, blue)

  color = rl.Color { red, green, blue, 255 }

  return TerrainCell {
    altitude,
    color,
    { x, y },
  }
}



// Generate random gradient vector.
gradient :: proc(h: f32) -> [2]f32 {
  return { math.cos(h), math.sin(h) }
}

// Linear interpolation.
lerp :: proc(a, b, x: f32) -> f32 {
  return a + x * (b - a)
}

// Smoothstep interpolation.
fade :: proc(t: f32) -> f32 {
  return t * t * t * (t * (t * 6 - 15) + 10)
}

// Compute Perlin noise for coordinates (x, y).
perlin :: proc(x, y: f32, grid_size: f32 = 8) -> f32 {
  x0, y0: int = int(x / grid_size), int(y / grid_size)
  x1, y1: int = x0 + 1, y0 + 1

  dx, dy: f32 = x / grid_size - f32(x0), y / grid_size - f32(y0)

  gradients: [4][2]f32 = {}
  // gradients[(x0, y0)] = gradient(random.random() * 2 * math.pi)
  // gradients[(x1, y0)] = gradient(random.random() * 2 * math.pi)
  // gradients[(x0, y1)] = gradient(random.random() * 2 * math.pi)
  // gradients[(x1, y1)] = gradient(random.random() * 2 * math.pi)

  gradients[0] = gradient(rand.float32() * 2 * math.PI)
  gradients[1] = gradient(rand.float32() * 2 * math.PI)
  gradients[2] = gradient(rand.float32() * 2 * math.PI)
  gradients[3] = gradient(rand.float32() * 2 * math.PI)

  dot00, dot10: f32 = gradients[0][0]*dx + gradients[0][1]*dy, gradients[1][0]*(dx-1) + gradients[1][1]*dy
  dot01, dot11: f32 = gradients[2][0]*dx + gradients[2][1]*(dy-1), gradients[3][0]*(dx-1) + gradients[3][1]*(dy-1)
  //
  u, v: f32 = fade(dx), fade(dy)
  //
  return lerp(lerp(dot00, dot10, u), lerp(dot01, dot11, u), v)
}


generate :: proc(#any_int width, height: int) -> [dynamic][dynamic]TerrainCell {
  mapWidth, mapHeight: int
  // terrain: map[int]map[int]TerrainCell
  terrain: [dynamic][dynamic]TerrainCell

  local_seed := i64(30298) //rand.int63()

  mapWidth = int(width / scale)
  mapHeight = int(height / scale)

  distance_to_center, max_distance, dx, dy, y_scaling_coef: f32


  // 0.25 is for 0.5 * 0.5
  max_distance = math.sqrt(f32(mapWidth) * f32(mapWidth) * 0.25 + f32(mapHeight) * f32(mapHeight) * 0.25)

  // This is done to compensate the fact that the rectangle window would make the main continent "oval"
  y_scaling_coef = f32(width) / f32(height)

    terrain = make([dynamic][dynamic]TerrainCell, mapHeight)

  for y in 0..<mapHeight {
    terrain[y] = make([dynamic]TerrainCell, mapWidth)

    for x in 0..<mapWidth {

      // Distance from the center minus pos
      dx = f32(f32(mapWidth) * 0.5 - f32(x))
      dy = f32(f32(mapHeight) * 0.5 - f32(y))
      distance_to_center = math.sqrt(dx * dx + dy * dy * y_scaling_coef)
      altitude := 0.75 - 2 * distance_to_center / max_distance

      // noise_value := math.abs(noise.noise_2d_improve_x(local_seed, { f64(x) * noise_scale, f64(y) * noise_scale }) / 2)
      // noise_value := noise.noise_2d_improve_x(local_seed, { f64(x) * noise_scale, f64(y) * noise_scale }) / 2
      noise_value := noise.noise_2d_improve_x(local_seed, { f64(x) * noise_scale, f64(y) * noise_scale }) / 2
      altitude += noise_value
      // 2 * is to scale the noise to -1 => 1 (negatives are for sea level)
      // altitude += 2.0 * noise_value - 1.0
      // altitude = noise_value

      terrain[y][x] = create_cell(y, x, altitude)
    }
  }

  fmt.println(mapWidth, mapHeight)

  return terrain
}

draw_terrain :: proc(terrain: ^[dynamic][dynamic]TerrainCell) {
  for &line in terrain {
    for &cell in line {
      display_cell(&cell)
    }
  }
}

display_cell :: proc(cell: ^TerrainCell) {
  rl.DrawRectangle(i32(cell.position.x * scale), i32(cell.position.y * scale), scale, scale, cell.color)
}

scale :: 1
noise_scale :: 0.015
// noise_scale :: 1
seed :: 1
