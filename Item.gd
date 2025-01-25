extends Node3D
class_name Item

@export var slot_texture: CompressedTexture2D = null
var thing_holding_me: Node = null

func use_item() -> void:
	pass

func get_dropped() -> void:
	thing_holding_me = null

func get_picked_up_by(new_owner: Node) -> void:
	thing_holding_me = new_owner

func reload_item() -> void:
	pass

func alt_use_item() -> void:
	pass
