extends Node3D
class_name Item
# An abstract class that all Items (ItemGeneric, ItemUsable) inherit

var thing_holding_me: Node3D = null

# Inventory Management
@export var inventory_texture: Texture = null

var item_components: Array[Node] = []

func get_picked_up() -> void:
	Debug.debug("Picked up")
	# disable layer 4 (held item layer)
	get_node("MeshInstance3D").layers = 8
	item_components = find_children("Item*", "Item", false) 
	var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
	if animation_player != null:
		animation_player.play("pickup")
	for child in get_children():
		if child is CollisionShape3D:
			Debug.debug("disabling hitbox")
			child.disabled = true

func get_dropped() -> void:
	Debug.debug("Dropped")
	# enable layer 4 (held item layer)
	get_node("MeshInstance3D").layers = 1
	item_components = []
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = false
