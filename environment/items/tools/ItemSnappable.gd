extends Node3D
class_name ItemSnappableComponent

# Used for snapping items into sockets, like keys into locks.

func _ready() -> void:
	assert(get_parent() is Item)
