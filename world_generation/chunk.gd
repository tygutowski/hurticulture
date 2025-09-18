extends Node3D
class_name Chunk

var colors: Dictionary[int, Color] = {
	0: Color("f9f7dc"),
	1: Color("f2efbb"),
	2: Color("c5d86d"),
	3: Color("9ebc63"),
	4: Color("82aa57"),
	5: Color("618943"),
}

# in Chunk.gd (or set on the instance)
var base_heightmap: Array[Array]        # immutable source
var neighbor_sig: PackedInt32Array = PackedInt32Array() # [N,S,W,E] last seen
var lod: int


# these raise the lod for a side (so if LOD is 3, the north side would become LOD 4)
# this is used for blending LODs
@export var north_simplified: bool
@export var south_simplified: bool
@export var east_simplified: bool
@export var west_simplified: bool

var coords: Vector2
@export var chunk_heightmap: Array
