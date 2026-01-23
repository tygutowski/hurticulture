extends Node3D

@onready var light: SpotLight3D = get_node_or_null("SpotLight3D")

func _ready() -> void:
	disable()

func enable() -> void:
	print("attempt to enable " + str(name))
	print(get_parent())
	#if light == null:
	#	return
	light.spot_range = 8

func disable() -> void:
	print("attempt to disable " + str(name))
	print(get_parent())
	#if light == null:
	#	return
	light.spot_range = 0
