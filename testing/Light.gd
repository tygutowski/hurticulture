extends Node3D

@onready var light: SpotLight3D = get_node_or_null("SpotLight3D")

func _ready() -> void:
	disable()

func enable() -> void:
	if get_parent().viewport_type == get_parent().viewportType.FIRSTPERSON:
		return
	light.spot_range = 8

func disable() -> void:
	print(get_parent().viewport_type)
	if get_parent().viewport_type == get_parent().viewportType.FIRSTPERSON:
		return
	light.spot_range = 0
