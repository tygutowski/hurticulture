extends Node3D

func _ready() -> void:
	get_node("WorldGenerator").generate_world()
