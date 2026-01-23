extends Node3D

func _ready() -> void:
	disable()

func enable() -> void:
	print("en")
	$OmniLight3D.omni_range = 8

func disable() -> void:
	print("dis")
	$OmniLight3D.omni_range = 0
