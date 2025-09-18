extends Node
class_name TerrainGenerator

var map_generator: MapGenerator

@export_category("Terrain Generation")
@export var continent_piecewise: Curve
@export var erosion_piecewise: Curve
@export var peaks_and_valleys_piecewise: Curve

@export var continent_map: FastNoiseLite
@export var erosion_map: FastNoiseLite
@export var peaks_and_valleys_map: FastNoiseLite

@export_category("Biome Generation")
@export var temperature_map: FastNoiseLite
@export var humidity_map: FastNoiseLite
@export var weirdness_map: FastNoiseLite

func update_chunks() -> void:
	get_parent().update_visible_chunks()

func get_height(coords: Vector2) -> float:
	var continent_noise: float = (continent_map.get_noise_2dv(coords) + 1.0) * 0.5
	var erosion_noise: float = (erosion_map.get_noise_2dv(coords) + 1.0) * 0.5
	var peaks_noise: float = (peaks_and_valleys_map.get_noise_2dv(coords) + 1.0) * 0.5
	
	var continent_height: float = continent_piecewise.sample(continent_noise)
	var erosion_height: float = erosion_piecewise.sample(erosion_noise)
	var peaks_and_valleys_height: float = peaks_and_valleys_piecewise.sample(peaks_noise)
	
	# blend them progressively
	var erosion_factor: float = smoothstep(0.4, 1.0, continent_noise)
	var base: float = lerp(continent_height, erosion_height, erosion_factor)

	var peaks_and_valleys_factor: float = smoothstep(0.7, 1.0, erosion_noise)
	base = lerp(base, peaks_and_valleys_height, peaks_and_valleys_factor)

	return base

func get_height_from(x: float, curve: Curve) -> float:
	#TODO: change to sample_baked in the future.
	return curve.sample(x)
