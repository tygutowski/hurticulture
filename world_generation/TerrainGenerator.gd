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

func get_height_data(coords: Vector2) -> Dictionary:
	var continent_noise: float = (continent_map.get_noise_2dv(coords) + 1.0) * 0.5
	var erosion_noise: float = (erosion_map.get_noise_2dv(coords) + 1.0) * 0.5
	var peaks_noise: float = (peaks_and_valleys_map.get_noise_2dv(coords) + 1.0) * 0.5

	var continent_height: float = continent_piecewise.sample(continent_noise) / (continent_map.frequency * 200)
	var erosion_height: float = erosion_piecewise.sample(erosion_noise) / (erosion_map.frequency * 50)
	var peaks_height: float = peaks_and_valleys_piecewise.sample(peaks_noise) / (peaks_and_valleys_map.frequency * 10)

	# erosion modifies continent at 30%
	var continent_with_erosion: float = lerp(continent_height, erosion_height, 0.3)

	# peaks modify erosion-stage result at 30%
	var final_height: float = lerp(continent_with_erosion, peaks_height, 0.3)

	return {
		"height": final_height,
		"continent": continent_noise,
		"erosion": erosion_noise,
		"peaks": peaks_noise
	}


func generate_chunk_data(chunk: Chunk) -> void:
	var chunk_pos: Vector2 = chunk.coords * get_parent().chunk_size
	chunk.biome_map.resize(get_parent().subchunks_per_chunk)
	for x: int in range(0, get_parent().subchunks_per_chunk):
		chunk.biome_map[x] = []

		for y: int in range(0, get_parent().subchunks_per_chunk):
			var world_pos: Vector2 = Vector2(
				chunk_pos.x + x * get_parent().subchunk_length,
				chunk_pos.y + y * get_parent().subchunk_length
			)

			var data = get_height_data(world_pos)
			var continent = data["continent"]
			var erosion  = data["erosion"]
			var temperature: float = temperature_map.get_noise_2dv(world_pos)
			var humidity: float = humidity_map.get_noise_2dv(world_pos)
			var weirdness: float = weirdness_map.get_noise_2dv(world_pos)

			var biome: Biome = get_parent().biome_generator.get_biome_at(
				self,
				temperature,
				humidity,
				weirdness,
				continent,
				erosion,
			)

			chunk.biome_map[x].append(biome)



func get_height_from(x: float, curve: Curve) -> float:
	#TODO: change to sample_baked in the future.
	return curve.sample(x)
