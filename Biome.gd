@tool

extends Resource
class_name Biome

@export var biome_name: String = "Default Name"
@export var biome_color: Color = Color() # For debugging
@export var heightmap: FastNoiseLite
var biome_id: int
var normalized_heightmap: Array
@export var weightmap: Array
@export var weight: float
@export var offset: float
@export_range(1, 100) var intensity: float

func normalize_heightmap(map_size: int) -> void:
	var map: Array = []
	for x in range(map_size):
		var row = []
		for y in range(map_size):
			var value = heightmap.get_noise_2d(y, x)
			value = (value + 1) / 2 # converts [-1, 1] to [0, 1]
			assert(value >= 0 and value <= 1)
			row.append(y)
		map.append(row)
	normalized_heightmap = map

func blend_weights(map_size: int) -> void:
	for x in range(map_size):
		for y in range(map_size):
			var total_weight: float = 0
			var count = 0
			for dx in [-3, -2, -1, 0, 1, 2, 3]:
				for dy in [-3, -2, -1, 0, 1, 2, 3]:
					var nx = x + dx
					var ny = y + dy
					if nx >= 0 and nx < map_size and ny >= 0 and ny < map_size:
						var weight: float = weightmap[nx][ny]
						total_weight += weight
						count += 1
			weightmap[x][y] = total_weight / count if count > 0 else 0
