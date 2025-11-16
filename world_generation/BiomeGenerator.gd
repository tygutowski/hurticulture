extends Node
class_name BiomeGenerator

enum biomeEnum {
	DESERT,
	TUNDRA,
	JUNGLE,
	PLAINS
}

const TEMP_BANDS: Array[float] = [0.33, 0.66]
const HUMID_BANDS: Array[float] = [0.33, 0.66]

const BIOME_TABLE := [
	[biomeEnum.TUNDRA, biomeEnum.PLAINS, biomeEnum.PLAINS],  # cold
	[biomeEnum.PLAINS, biomeEnum.PLAINS, biomeEnum.JUNGLE],  # warm
	[biomeEnum.DESERT, biomeEnum.DESERT, biomeEnum.PLAINS]   # hot
]


var biome_list: Array[Biome] = [
	ResourceLoader.load("res://world_generation/biomes/desert_biome.tres", "Biome"),
	ResourceLoader.load("res://world_generation/biomes/tundra_biome.tres", "Biome"),
	ResourceLoader.load("res://world_generation/biomes/jungle_biome.tres", "Biome"),
	ResourceLoader.load("res://world_generation/biomes/plains_biome.tres", "Biome")
]

func initialize() -> void:
	for biome in biome_list:
		assert(biome != null, "Biome must not be null")
		assert(biome is Biome, "Biome must be of type Biome")

func bucket(v: float, bands: Array[float]) -> int:
	for i: int in bands.size():
		if v <= bands[i]:
			return i
	# return last item
	return bands.size()

func get_biome_at(height: float, temperature: float, humidity: float, weirdness: float) -> Biome:
	var t_idx: int = bucket((temperature + 1) / 2, TEMP_BANDS)
	var h_idx: int = bucket((humidity + 1) / 2, HUMID_BANDS)
	var biome_id: int = BIOME_TABLE[t_idx][h_idx]
	return biome_list[biome_id]
