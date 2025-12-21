package perlin_noise

import "core:fmt"
import noise "core:math/noise"
import rand "core:math/rand"
import math "core:math"
import rl "vendor:raylib"

// 16x16

TerrainCell :: struct {
  altitude: f32,
  color: rl.Color,
  tileset_pos: [2]int,
  position: [2]int,
}
  // // fmt.println("altitude: ", altitude)

create_cell :: proc(y, x: int, altitude: f32) -> TerrainCell {
  color: rl.Color
  red, green, blue: u8 = 0, 0, 0
  tileset_pos: [2]int= { -1, -1 }

  altitude := altitude
  // altitude -= distance_to_center / 1000

  // if altitude < -0.3 {
  //   blue = u8(math.remap_clamped(altitude, -0.8, -0.3, 0, 255))
  //   // blue = 100
  // }
  //
  // if altitude >= -0.3 && altitude < 0 {
  //   green = u8(math.remap_clamped(altitude, -0.3, 0, 50, 200))
  // }
  //
  // if altitude >= 0 && altitude < 0.3 {
  //   green = u8(math.remap_clamped(altitude, 0, 0.3, 50, 200))
  //   blue = u8(math.remap_clamped(altitude, 0, 0.3, 0, 100))
  //   // green = 255
  // }
  //
  // if altitude >= 0.3 && altitude < 0.4 {
  //   red = u8(math.remap_clamped(altitude, 0.3, 0.4, 150, 230))
  //   // red = 200
  // }
  //


  if altitude < -0.3 {
    blue = 200
    // red = 255
  }

  // Sand
  if altitude > -0.3 && altitude < -0.2 {
    tileset_pos = { 20, 2 }
    blue = 200
  }

  // Hills
  if altitude >= -0.2 && altitude < -0.1 {
    tileset_pos = { 10, 0 }
    green = 150
  }

  // Hills
  if altitude >= -0.1 && altitude < 0 {
    tileset_pos = { 20, 0 }
    green = 150
  }

  // Grass
  if altitude >= 0 && altitude < 0.1 {
    tileset_pos = { 5, 0 }
    green = 150
  }

  // Grass 2
  if altitude >= 0.1 && altitude < 0.2 {
    tileset_pos = { 13, 0 }
    green = 250
  }

  if altitude >= 0.2 && altitude < 0.25 {
    blue = 255
  }

  // Dark grass
  if altitude >= 0.25 && altitude < 0.35 {
    tileset_pos = { 4, 6 }

    green = 50
  }

  // Forest
  if altitude >= 0.35 && altitude < 0.45 {
    tileset_pos = { 2, 16 }
    green = 150
  }

  // Dark Forest
  if altitude >= 0.45 && altitude < 0.5 {
    tileset_pos = { 21, 16 }
    red = 100
  }

  // Snow
  if altitude >= 0.5 && altitude < 0.7 {
    red = 200
    // tileset_pos = { 31, 3 }
    tileset_pos = { 12, 17 }
  }

  // Other (mountains)
  if abs(altitude - 0.5) < 0.03 {
    green = 0
    red = 0
    blue = 0
  }

  // mountains
  if altitude >= 0.7 && altitude < 0.9 {
    tileset_pos = { 15, 3 }

    red = 255
    green = 255
    blue = 255
  }

  // Snowy mountains
  if altitude >= 0.9 {
    tileset_pos = { 28, 3 }

    red = 255
    green = 255
    blue = 255
  }


  // red = u8(math.remap_clamped(altitude, -1, 1, 0, 255))
  // green = red
  // blue = red
  // if altitude >= 0.2 && altitude < 0.3 {
  //   red = u8(math.remap_clamped(altitude, 0.2, 0.3, 100, 255))
  // }
  color = rl.Color { red, green, blue, 255 }

  return TerrainCell {
    altitude,
    color,
    tileset_pos,
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



permutation: [256]int = { 151,160,137,91,90,15,                 // Hash lookup table as defined by Ken Perlin.  This is a randomly
    131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,    // arranged array of all numbers from 0-255 inclusive.
    190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
    88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
    77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
    102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
    135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
    5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
    223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
    129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
    251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
    49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
    138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180 }

p: [512]int

permutate :: proc() {
  for x in 0..<512 {
    p[x] = permutation[x%256]
  }
}

inc ::proc(num: int) -> int {
  num := num

  num += 1

  // if (repeat > 0) do num %= repeat

  return num
}

// Source: http://riven8192.blogspot.com/2010/08/calculate-perlinnoise-twice-as-fast.html
grad :: proc(hash: int, x, y, z: f32) -> f32 {
  switch(hash & 0xF) {
  case 0x0: return  x + y
  case 0x1: return -x + y
  case 0x2: return  x - y
  case 0x3: return -x - y
  case 0x4: return  x + z
  case 0x5: return -x + z
  case 0x6: return  x - z
  case 0x7: return -x - z
  case 0x8: return  y + z
  case 0x9: return -y + z
  case 0xA: return  y - z
  case 0xB: return -y - z
  case 0xC: return  y + x
  case 0xD: return -y + z
  case 0xE: return  y - x
  case 0xF: return -y - z
  }

  return 0 // never happens
}

// Compute Perlin noise for coordinates (x, y).
perlin :: proc(x, y, z: f32) -> f32 {
  @(static) initialized := false

  if !initialized {
    permutate()
    initialized = true
  }

  xi: int = int(x) & 255                              // Calculate the "unit cube" that the point asked will be located in
  yi: int = int(y) & 255                              // The left bound is ( |_x_|,|_y_|,|_z_| ) and the right bound is that
  zi: int = int(z) & 255                              // plus 1.  Next we calculate the location (from 0.0 to 1.0) in that cube.
  xf: f32 = x-f32(int(x))
  yf: f32 = y-f32(int(y))
  zf: f32 = z-f32(int(z))

   u: f32 = fade(xf)
  v: f32 = fade(yf)
     w: f32 = fade(zf)

    aaa, aba, aab, abb, baa, bba, bab, bbb: int

    aaa = p[p[p[    xi ]+    yi ]+    zi ]
    aba = p[p[p[    xi ]+inc(yi)]+    zi ]
    aab = p[p[p[    xi ]+    yi ]+inc(zi)]
    abb = p[p[p[    xi ]+inc(yi)]+inc(zi)]
    baa = p[p[p[inc(xi)]+    yi ]+    zi ]
    bba = p[p[p[inc(xi)]+inc(yi)]+    zi ]
    bab = p[p[p[inc(xi)]+    yi ]+inc(zi)]
    bbb = p[p[p[inc(xi)]+inc(yi)]+inc(zi)]


 x1, x2, y1, y2: f32
    x1 = lerp(    grad (aaa, xf  , yf  , zf),           // The gradient function calculates the dot product between a pseudorandom
                grad (baa, xf-1, yf  , zf),             // gradient vector and the vector from the input coordinate to the 8
                u)                                     // surrounding points in its unit cube.
    x2 = lerp(    grad (aba, xf  , yf-1, zf),           // This is all then lerped together as a sort of weighted average based on the faded (u,v,w)
                grad (bba, xf-1, yf-1, zf),             // values we made earlier.
                  u)
    y1 = lerp(x1, x2, v)

    x1 = lerp(    grad (aab, xf  , yf  , zf-1),
                grad (bab, xf-1, yf  , zf-1),
                u)
    x2 = lerp(    grad (abb, xf  , yf-1, zf-1),
                  grad (bbb, xf-1, yf-1, zf-1),
                  u)
    y2 = lerp (x1, x2, v)
    
    return (lerp (y1, y2, w)+1)/2




  // x0, y0: int = int(x / grid_size), int(y / grid_size)
  // x1, y1: int = x0 + 1, y0 + 1
  //
  // dx, dy: f32 = x / grid_size - f32(x0), y / grid_size - f32(y0)
  //
  // gradients: [4][2]f32 = {}
  // // gradients[(x0, y0)] = gradient(random.random() * 2 * math.pi)
  // // gradients[(x1, y0)] = gradient(random.random() * 2 * math.pi)
  // // gradients[(x0, y1)] = gradient(random.random() * 2 * math.pi)
  // // gradients[(x1, y1)] = gradient(random.random() * 2 * math.pi)
  //
  // gradients[0] = gradient(rand.float32() * 2 * math.PI)
  // gradients[1] = gradient(rand.float32() * 2 * math.PI)
  // gradients[2] = gradient(rand.float32() * 2 * math.PI)
  // gradients[3] = gradient(rand.float32() * 2 * math.PI)
  //
  // dot00, dot10: f32 = gradients[0][0]*dx + gradients[0][1]*dy, gradients[1][0]*(dx-1) + gradients[1][1]*dy
  // dot01, dot11: f32 = gradients[2][0]*dx + gradients[2][1]*(dy-1), gradients[3][0]*(dx-1) + gradients[3][1]*(dy-1)
  // //
  // u, v: f32 = fade(dx), fade(dy)
  // //
  // return lerp(lerp(dot00, dot10, u), lerp(dot01, dot11, u), v)
}


OctavePerlin :: proc(x, y, z: f32, octaves: int, persistence: f32) -> f32 {
  total: f32  = 0
    frequency: f32  = 1
    amplitude: f32  = 1
    maxValue: f32 = 0  // Used for normalizing result to 0.0 - 1.0

    for i in 0..<octaves{
        total += perlin(x * frequency, y * frequency, z * frequency) * amplitude
        // total += noise.noise_3d_improve_xy(109, { f64(x * frequency), f64(y * frequency), f64(z * frequency) }) * amplitude
        // total += noise.noise_2d(109, { f64(x * frequency), f64(y * frequency) }) * amplitude
        
        maxValue += amplitude
        
        amplitude *= persistence
        frequency *= 2
    }
    
    return total/maxValue
}

// All taken from  https://adrianb.io/2014/08/09/perlinnoise.html

generate :: proc(#any_int width, height: int, scale: i32, noise_scale: f32, #any_int start_x: int = 0, #any_int start_y: int = 0 ) -> [dynamic][dynamic]TerrainCell {
  mapWidth, mapHeight: int
  // terrain: map[int]map[int]TerrainCell
  terrain: [dynamic][dynamic]TerrainCell

  @(static) z: f32 = 0.0

  // z += 1

  // for i in 1..<512 {
  //   p[i] = int(rand.int31()) % 255 //p[i - 1 % 255]
  // }


  mapWidth = width / int(scale)
  mapHeight = height / int(scale)

  distance_to_center, max_distance, dx, dy, y_scaling_coef: f32


  // 0.25 is for 0.5 * 0.5
  max_distance = math.sqrt(f32(mapWidth) * f32(mapWidth) * 0.25 + f32(mapHeight) * f32(mapHeight) * 0.25) + f32(mapWidth) / 1.5

  // This is done to compensate the fact that the rectangle window would make the main continent "oval"
  // y_scaling_coef = f32(width) / f32(height)
  y_scaling_coef = 5

  // y_scaling_coef -= start_y > 0 ? 4 : 0

  fmt.println(y_scaling_coef)

    terrain = make([dynamic][dynamic]TerrainCell, mapHeight)

  for y in 0..<(mapHeight) {
    terrain[y] = make([dynamic]TerrainCell, mapWidth)
    relative_y := y + start_y

    for x in 0..<(mapWidth) {

      relative_x := x + start_x

      altitude: f32 = 0.0

      // Distance from the center minus pos
      dx = f32(f32(mapWidth) * 1.5 * 0.5 - f32(relative_x))
      dy = f32(f32(mapHeight) * 1.5 * 0.5 - f32(relative_y))
      // distance_to_center =  math.sqrt(dx * dx + dy * dy * y_scaling_coef)
      distance_to_center =  math.sqrt(dx * dx + dy * dy * y_scaling_coef)

      // altitude = 0.1 - 2 * (2/8.0 * distance_to_center) / max_distance

      altitude = 0.65 - 2 * (2/26.0 * distance_to_center) / max_distance
      altitude -= 0.4 * (distance_to_center / max_distance)

      noise_value:= OctavePerlin(f32(relative_x) * noise_scale, f32(relative_y) * noise_scale, z * noise_scale, 5, 0.4)

      // fmt.println(altitude)
      // noise_value := noise.noise_2d(local_seed, { f64(x) * noise_scale, f64(y) * noise_scale }) / 1.3
      // noise_value := noise.noise_2d_improve_x(local_seed, { f64(x) * noise_scale, f64(y) * noise_scale }) / 2
      // noise_value := (noise.noise_2d_improve_x(local_seed, { f64(x) * noise_scale, f64(y) * noise_scale }) + 1) / 2

      // noise_value: f32 = 0.0 // perlin(f32(x) * noise_scale, f32(y) * noise_scale, 100)
      // altitude += noise_value
      // 2 * is to scale the noise to -1 => 1 (negatives are for sea level)

      altitude += 2.0 * noise_value - 1.0
      // altitude = noise_value

      terrain[y][x] = create_cell(y, x, altitude)
    }
  }

  return terrain
}

draw_terrain :: proc(terrain: ^[dynamic][dynamic]TerrainCell, scale: i32, tileset: rl.Texture2D) {
  for &line in terrain {
    for &cell in line {
      display_cell(&cell, scale, tileset)
    }
  }
}

display_cell :: proc(cell: ^TerrainCell, scale: i32, tileset: rl.Texture2D) {
  if cell.tileset_pos.x == -1 && cell.tileset_pos.y == -1 {
    rl.DrawRectangle(i32(cell.position.x) * 8, i32(cell.position.y) * 8, 8, 8, cell.color)
 } else {
    source := rl.Rectangle { f32(cell.tileset_pos.x) * 16, f32(cell.tileset_pos.y) * 16, -16, -16 }
    dest := rl.Rectangle { f32(i32(cell.position.x) * 8), f32(i32(cell.position.y) * 8), f32(8), f32(8 )}

    rl.DrawTexturePro(tileset, source, dest, { 0, 0 }, 0, rl.WHITE)
  }

}

// scale :: 1
// noise_scale :: 0.02
// noise_scale :: 1
seed :: 1
