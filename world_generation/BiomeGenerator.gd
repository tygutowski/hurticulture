extends Node
class_name BiomeGenerator

var biomes: Array = [
	["DESERT", "TUNDRA"],
	["JUNGLE", "PLAINS"]
]

var biome_dict: Dictionary[String, Biome] = {
	"DESERT": preload("res://world_generation/biomes/desert_biome.tres"),
	"TUNDRA": preload("res://world_generation/biomes/tundra_biome.tres"),
	"JUNGLE": preload("res://world_generation/biomes/jungle_biome.tres"),
	"FOREST": preload("res://world_generation/biomes/plains_biome.tres")
}

var map_generator: MapGenerator

func initialize() -> void:
	pass

func get_biome(coords: Vector2, height_map: Array, heat_map: Array, moisture_map: Array) -> int:
	var height: float = height_map[coords.x][coords.y]
	var heat: float = heat_map[coords.x][coords.y]
	var moisture: float = moisture_map[coords.x][coords.y]
	print(height, heat, moisture)

	return 0

func convert_noise_to_array(map_size: int, noise: FastNoiseLite) -> Array:
	var array: Array = []
	for x in range(map_size):
		var row: Array = []
		for y in range(map_size):
			var value: float = noise.get_noise_2d(x, y)
			row.append(value)
		array.append(row)
	return array

func split_biomes_by_weight(map_size, biome_map: Array, biome_weights: Array) -> Array:
	var split_biome_map = []

	# Initialize each layer map for the biome ID ranges
	for i in range(len(biome_weights)):
		var layer_map: Array = []
		for y in range(map_size + 1):
			var row = []
			for x in range(map_size + 1):
				row.append(0)
			layer_map.append(row)
		split_biome_map.append(layer_map)

	for y in range(map_size + 1):
		for x in range(map_size + 1):
			var value = biome_map[y][x]
			for i in range(len(biome_weights) - 1):
				if biome_weights[i] <= value and value < biome_weights[i + 1]:
					split_biome_map[i][y][x] = 1
					break
	return split_biome_map

func distribute_weights_to_biomes(biome_list, biome_map_split: Array) -> void:
	for i: int in range(len(biome_list)):
		var biome: Biome = biome_list[i]
		biome.weight_map = biome_map_split[i]

func set_biome_ids(biome_list) -> void:
	for i: int in range(len(biome_list)):
		var biome: Biome = biome_list[i]
		biome.biome_id = i
