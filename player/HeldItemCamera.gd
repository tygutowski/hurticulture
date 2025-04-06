extends Camera3D

@export var main_camera: Camera3D

func _process(_delta: float) -> void:
	global_transform = main_camera.global_transform
	v_offset = main_camera.v_offset
	h_offset = main_camera.h_offset
	fov = main_camera.fov
