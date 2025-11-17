extends Node
class_name BiomeGenerator

const TEMP_BANDS: Array[float] = [0.33, 0.66]
const HUMID_BANDS: Array[float] = [0.33, 0.66]

const BIOME_TABLE := [
	[Global.biomeEnum.SKYLOOM_MEADOW, Global.biomeEnum.SKYLOOM_MEADOW, Global.biomeEnum.SKYLOOM_MEADOW],  # cold
	[Global.biomeEnum.CARBON_WASTES, Global.biomeEnum.SKYLOOM_MEADOW, Global.biomeEnum.SKYLOOM_MEADOW],  # warm
	[Global.biomeEnum.CARBON_WASTES, Global.biomeEnum.CARBON_WASTES, Global.biomeEnum.CARBON_WASTES]   # hot
]


var biome_list: Array[Biome] = [
	ResourceLoader.load("res://world_generation/biomes/carbon_wastes_biome.tres", "Biome"),
	ResourceLoader.load("res://world_generation/biomes/skyloom_meadow_biome.tres", "Biome"),
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

func get_biome_at(_height: float, temperature: float, humidity: float, _weirdness: float) -> Biome:
	var t_idx: int = bucket((temperature + 1) / 2, TEMP_BANDS)
	var h_idx: int = bucket((humidity + 1) / 2, HUMID_BANDS)
	var biome_id: int = BIOME_TABLE[t_idx][h_idx]
	return biome_list[biome_id]
