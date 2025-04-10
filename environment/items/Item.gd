extends Node3D
class_name Item
# An abstract class that all Items (ItemGeneric, ItemUsable) inherit

var thing_holding_me: Node3D = null

# Inventory Management
@export var inventory_texture: Texture = null
@export var two_handed: bool = false

var item_components: Array[Node] = []

func _ready() -> void:
	if two_handed:
		assert(has_node("SecondaryHandPoint"), "A two handed item must have a SecondaryHandPoint")
	set_render_layer(1)

func get_picked_up() -> void:
	Debug.debug("Picked up")
	# disable layer 4 (held item layer)
	set_render_layer(8)
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
	# enable layer 1 (normal world layer)
	set_render_layer(1)
	item_components = []
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = false

func set_render_layer(layer_bitmap: int) -> void:
	var meshes = find_children("*", "MeshInstance3D", true)
	for mesh in meshes:
		mesh.layers = layer_bitmap

func get_secondary_hand_position() -> Vector3:
	return get_node("SecondaryHandPoint").position
