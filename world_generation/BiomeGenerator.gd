extends Node
class_name BiomeGenerator

const TEMP_BANDS: Array[float] = [0.33, 0.66]
const HUMID_BANDS: Array[float] = [0.33, 0.66]

const ELEV_WATER: int = 0
const ELEV_BEACH: int = 1
const ELEV_LAND: int = 2
const ELEV_MOUNTAIN: int = 3
const ELEV_PEAK: int = 4

# hot wet    cold wet
# 
# hot dry    cold dry
const BIOME_TABLE := [
	[
		[Global.biomeEnum.TITANPAD_MIRE, Global.biomeEnum.TITANPAD_MIRE, Global.biomeEnum.TITANPAD_MIRE],
		[Global.biomeEnum.TITANPAD_MIRE, Global.biomeEnum.TITANPAD_MIRE, Global.biomeEnum.TITANPAD_MIRE],
		[Global.biomeEnum.TITANPAD_MIRE, Global.biomeEnum.TITANPAD_MIRE, Global.biomeEnum.TITANPAD_MIRE]
	],
	[
		[Global.biomeEnum.TITANPAD_MIRE, Global.biomeEnum.TITANPAD_MIRE, Global.biomeEnum.TITANPAD_MIRE],
		[Global.biomeEnum.TITANPAD_MIRE, Global.biomeEnum.TITANPAD_MIRE, Global.biomeEnum.TITANPAD_MIRE],
		[Global.biomeEnum.TITANPAD_MIRE, Global.biomeEnum.TITANPAD_MIRE, Global.biomeEnum.TITANPAD_MIRE]
	],
	[
		[Global.biomeEnum.SKYLOOM_MEADOW, Global.biomeEnum.SKYLOOM_MEADOW, Global.biomeEnum.SKYLOOM_MEADOW],
		[Global.biomeEnum.SKYLOOM_MEADOW, Global.biomeEnum.SKYLOOM_MEADOW, Global.biomeEnum.SKYLOOM_MEADOW],
		[Global.biomeEnum.SKYLOOM_MEADOW, Global.biomeEnum.SKYLOOM_MEADOW, Global.biomeEnum.SKYLOOM_MEADOW]
	],
	[
		[Global.biomeEnum.CARBON_WASTES, Global.biomeEnum.CARBON_WASTES, Global.biomeEnum.CARBON_WASTES],
		[Global.biomeEnum.CARBON_WASTES, Global.biomeEnum.CARBON_WASTES, Global.biomeEnum.CARBON_WASTES],
		[Global.biomeEnum.CARBON_WASTES, Global.biomeEnum.CARBON_WASTES, Global.biomeEnum.CARBON_WASTES]
	],
	[
		[Global.biomeEnum.CARBON_WASTES, Global.biomeEnum.CARBON_WASTES, Global.biomeEnum.CARBON_WASTES],
		[Global.biomeEnum.CARBON_WASTES, Global.biomeEnum.CARBON_WASTES, Global.biomeEnum.CARBON_WASTES],
		[Global.biomeEnum.CARBON_WASTES, Global.biomeEnum.CARBON_WASTES, Global.biomeEnum.CARBON_WASTES]
	],
]

var biome_list: Array[Biome] = [
	ResourceLoader.load("res://world_generation/biomes/carbon_wastes_biome.tres", "Biome"),
	ResourceLoader.load("res://world_generation/biomes/skyloom_meadow_biome.tres", "Biome"),
	ResourceLoader.load("res://world_generation/biomes/titanpad_mire_biome.tres", "Biome")
]

func _ready() -> void:
	for biome: Biome in biome_list:
		assert(biome != null)
		assert(biome is Biome)

func _bucket(v: float, bands: Array[float]) -> int:
	for i: int in bands.size():
		if v <= bands[i]:
			return i
	return bands.size()

func classify_elevation(
	continent: float,
) -> int:
	if continent < 0.2:
		return ELEV_WATER
	elif continent < 0.3:
		return ELEV_BEACH
	elif continent < 0.75:
		return ELEV_LAND
	elif continent < 0.9:
		return ELEV_MOUNTAIN
	return ELEV_PEAK

func get_biome_at(
		_terrain_generator: TerrainGenerator,
		temperature: float,
		humidity: float,
		_weirdness: float,
		continent: float,
		_erosion: float
	) -> Biome:

	var e_idx: int = classify_elevation(continent)
	var t_idx: int = _bucket((temperature + 1.0) / 2.0, TEMP_BANDS)
	var h_idx: int = _bucket((humidity + 1.0) / 2.0, HUMID_BANDS)

	var biome_id: int = BIOME_TABLE[e_idx][t_idx][h_idx]
	return biome_list[biome_id]
