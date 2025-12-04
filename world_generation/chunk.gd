extends Node3D
class_name Chunk

var coords: Vector2 = Vector2.INF
@onready var mesh_instance: MeshInstance3D = get_node("TerrainMesh")
var is_new: bool = true
var is_dirty: bool = true
var biome_map: Array[Array]
var flat_array: Texture2DArray

func get_biome_at_world_pos(
		wx: float,
		wy: float,
		chunk: Chunk,
		chunk_size: int,
		subchunks_per_chunk: int
	) -> Biome:

	var local_x: int = int(wx) - int(chunk.coords.x * chunk_size)
	var local_y: int = int(wy) - int(chunk.coords.y * chunk_size)

	# how many tiles per subchunk (e.g. 16 / 8 = 2)
	var subchunk_length: int = chunk_size / subchunks_per_chunk

	# convert tile coords → subchunk coords
	var sx: int = local_x / subchunk_length
	var sy: int = local_y / subchunk_length

	# clamp to avoid out-of-bounds on edges
	sx = clamp(sx, 0, subchunks_per_chunk - 1)
	sy = clamp(sy, 0, subchunks_per_chunk - 1)

	return chunk.biome_map[sx][sy]
