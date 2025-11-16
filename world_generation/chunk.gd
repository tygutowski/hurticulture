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
