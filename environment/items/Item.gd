extends Node3D
class_name Item
# An abstract class that all Items (ItemGeneric, ItemUsable) inherit

var thing_holding_me: Node3D = null

# Inventory Management
@export var inventory_texture: Texture = null

func get_picked_up() -> void:
	var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
	if animation_player != null:
		animation_player.play("pickup")
	for child in get_children():
		if child is CollisionShape3D:
			Debug.debug("disabling hitbox")
			child.disabled = true

func get_dropped() -> void:
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = false
