extends Node3D
class_name Chunk

var coords: Vector2 = Vector2.INF

var lod: int = -1
var directions_to_downscale: Array[Vector2] = []
var previous_directions_to_downscale: Array[Vector2] = []
var is_new: bool = true
