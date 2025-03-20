extends Node3D
class_name Item
# An abstract class that all Items (ItemGeneric, ItemUsable) inherit

var player_holding_me: Node3D = null

# Inventory Management
var slot: Vector2i = Vector2i(-1, -1)
var occupying_slots: Array = []
@export var inventory_shape: Global.ItemShape = Global.ItemShape.Slot
@export var inventory_texture: Texture = null
@export var hotbar_texture: Texture = null

func _ready() -> void:
	print("item")
	print('2')
	occupying_slots = Global.item_shape_slot_occupation[inventory_shape]
	#assert(inventory_texture is Texture, "Item's inventory texture isn't a Texture")

func get_picked_up() -> void:
	get_node("Mesh").material_override.no_depth_test = true
	var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
	if animation_player != null:
		animation_player.play("pickup")
	for child in get_children():
		if child is CollisionShape3D:
			Debug.debug("disabling hitbox")
			child.disabled = true

func get_dropped() -> void:
	var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
	if animation_player != null:
		animation_player.stop()
	get_node("Mesh").material_override.no_depth_test = false
	for child in get_children():
		Debug.debug("child!")
		if child is CollisionShape3D:
			Debug.debug("enabling hitbox")
			child.disabled = false
	player_holding_me = null

func get_picked_up_by(new_owner: Node) -> void:
	player_holding_me = new_owner
	get_picked_up()
