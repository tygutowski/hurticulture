extends Node3D

@export var camera : Node3D

func _ready() -> void:
	if camera != null:
		camera.current = true
		camera.global_position = get_node("Lens").global_position
		camera.look_at(get_node("Direction").global_position)
