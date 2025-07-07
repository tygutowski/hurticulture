extends RigidBody3D
class_name Item
# An abstract class that all Items (ItemGeneric, ItemUsable) inherit

var thing_holding_me: Node3D = null
enum viewportType {
	REALWORLD = 0,
	FIRSTPERSON = 1
}

var viewport_type = viewportType.REALWORLD
@export var fps_hand_offset: Vector3
@export var fps_hand_rotation: Vector3
@export var inventory_texture: Texture = null
@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")

var item_components: Array = []

# Update the list of item components
func set_item_components() -> void:
	item_components = StandardFunctions.find_children_in_group("item_component", self)
	Debug.debug(item_components)

# this is called after being picked up
# its what orients the item based on if its in the real-world
# or the player's viewport
func orient_item() -> void:
	Debug.debug(viewport_type)
	if viewport_type == viewportType.REALWORLD:
		position = Vector3.ZERO
		rotation = Vector3.ZERO
	elif viewport_type == viewportType.FIRSTPERSON:
		position = fps_hand_offset
		rotation = fps_hand_rotation

# Called when this item is picked up
func get_picked_up_by(parent) -> void:
	freeze = true
	thing_holding_me = parent
	for child in get_children():
		if child is CollisionShape3D:
			Debug.debug("disabling hitbox")
			child.disabled = true

# Called when this item is dropped
func get_dropped() -> void:
	freeze = false
	thing_holding_me = null
	item_components = []
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = false
