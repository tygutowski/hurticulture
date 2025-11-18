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

var generation_thread: Thread
var generation_mutex: Mutex

func initialize(_generation_thread: Thread = null, _generation_mutex: Mutex = null) -> void:
	generation_thread = _generation_thread
	generation_mutex = _generation_mutex
	
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

			var height: float = get_height(world_pos)
			var temp: float = temperature_map.get_noise_2dv(world_pos)
			var moist: float = humidity_map.get_noise_2dv(world_pos)
			var weird: float = weirdness_map.get_noise_2dv(world_pos)

			var biome: Biome = get_parent().biome_generator.get_biome_at(
				height,
				temp,
				moist,
				weird
			)

			chunk.biome_map[x].append(biome)



func get_height_from(x: float, curve: Curve) -> float:
	#TODO: change to sample_baked in the future.
	return curve.sample(x)
