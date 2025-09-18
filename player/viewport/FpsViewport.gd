extends Camera3D

@export var world_camera: Camera3D

func _process(_delta: float) -> void:
	global_transform = world_camera.global_transform

func _ready() -> void:
	fov = world_camera.fov
	v_offset = world_camera.v_offset / 5
	h_offset = world_camera.h_offset / 5
