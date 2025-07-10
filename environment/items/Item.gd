extends RigidBody3D
class_name Item
# An abstract class that all Items (ItemGeneric, ItemUsable) inherit

var thing_holding_me: Node3D = null
var has_outline: bool = false

enum viewportType {
	REALWORLD = 0,
	FIRSTPERSON = 1
}

enum materialType {
	METAL = 0,
	WOOD = 0
}

var viewport_counterpart: Item = null
var viewport_type = viewportType.REALWORLD

@export var item_name: String = "Default Item Name"
@export var inventory_texture: Texture = null
@export var fps_hand_offset: Vector3
@export var fps_hand_rotation: Vector3

@export var contact_sound_threshold: float = 3
@export var contact_sound_time: float = 0.1
@export var collision_material: int = materialType.METAL

@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")

var contact_sound_timer: float = 0
var item_components: Array = []

func _ready() -> void:
	# set this up so we can make noises when objects collide with things
	contact_monitor = true
	max_contacts_reported = 1

func _process(delta) -> void:
	contact_sound_timer -= delta

func _physics_process(_delta: float) -> void:
	check_for_collisions()

func check_for_collisions() -> void:
	if linear_velocity.length() > contact_sound_threshold:
		var contacts = get_contact_count()
		Debug.debug(contact_sound_timer)
		if contacts > 0 and (contact_sound_timer <= 0):
			make_contact_sound()

func make_contact_sound() -> void:
	contact_sound_timer = contact_sound_time
	get_node("ContactSound").play()

func set_counterpart(item: Item) -> void:
	viewport_counterpart = item

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
