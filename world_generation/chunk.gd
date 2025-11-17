extends Node3D
class_name Chunk

var coords: Vector2 = Vector2.INF

var is_new: bool = true
var is_dirty: bool = true

# 2d array of array
# size of chunk_size
# contains what biome each subchunk is 
var biome_map: Array[Array]
var flat_array: Texture2DArray

func get_biome_at_world_pos(wx: float, wy: float, chunk: Chunk, chunk_size: int) -> Biome:
	var lx: int = int(wx) - int(coords.x * chunk_size)
	var ly: int = int(wy) - int(coords.y * chunk_size)
	return chunk.biome_map[lx][ly]
