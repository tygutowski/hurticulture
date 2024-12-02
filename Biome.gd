@tool

extends Resource
class_name Biome

@export var flat_texture: Texture
@export var sloped_texture: Texture

@export var biome_name: String = "Default Name"
@export var biome_color: Color = Color() # For debugging
@export var heightmap: FastNoiseLite
var biome_id: int
var normalized_heightmap: Array
@export var weightmap: Array
@export var weight: float
var offset: float
@export_range(1, 100) var intensity: float
@export var material: Material

func prepare_textures() -> void:
	if sloped_texture == null:
		sloped_texture = flat_texture

func normalize_heightmap(map_size: int) -> void:
	var map: Array = []
	for x in range(map_size):
		var row = []
		for y in range(map_size):
			var value = heightmap.get_noise_2d(y, x)
			value = (value + 1) / 2 # converts [-1, 1] to [0, 1]
			assert(value >= 0 and value <= 1)
			row.append(value)
		map.append(row)
	normalized_heightmap = map

func blend_weights(map_size: int, blend_area: int, times_to_blend: int) -> void:
	var buffer = []
	for x in range(map_size):
		var row = []
		for y in range(map_size):
			row.append(0)
		buffer.append(row)

	for i in range(times_to_blend):
		# Compute horizontal rolling sums
		for x in range(map_size):
			var row_sum = 0.0
			for y in range(-blend_area, blend_area + 1):
				if y >= 0 and y < map_size:
					row_sum += weightmap[x][y]
			for y in range(map_size):
				buffer[x][y] = row_sum / (2 * blend_area + 1)
				if y + blend_area + 1 < map_size:
					row_sum += weightmap[x][y + blend_area + 1]
				if y - blend_area >= 0:
					row_sum -= weightmap[x][y - blend_area]

		# Compute vertical rolling sums
		for y in range(map_size):
			var col_sum = 0.0
			for x in range(-blend_area, blend_area + 1):
				if x >= 0 and x < map_size:
					col_sum += buffer[x][y]
			for x in range(map_size):
				weightmap[x][y] = col_sum / (2 * blend_area + 1)
				if x + blend_area + 1 < map_size:
					col_sum += buffer[x + blend_area + 1][y]
				if x - blend_area >= 0:
					col_sum -= buffer[x - blend_area][y]
