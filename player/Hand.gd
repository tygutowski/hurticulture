extends CanvasLayer

@export var movement_offset_multiplier: float = 0.5
@export var ads_offset_damp: float = 0.01
@export var main_camera: Camera3D
@export var holding_item_y_value: float = 0
@export var empty_hand_y_value: float = 60

# Nodes
@onready var subviewport_camera: Camera3D = get_node("SubViewportContainer/SubViewport/Camera3D")
@onready var hand: Node3D = subviewport_camera.get_node("Hand")

# Values
var item: Item = null
var holding_item: bool = false
var movement_offset: Vector2 = Vector2.ZERO
var base_hand_position: Vector3 = Vector3.ZERO  # The position to return to
var sway_offset: Vector3 = Vector3.ZERO         # Current sway offset

func add_item_to_hand(new_item: Item) -> void:
	item = new_item
	holding_item = true
	base_hand_position = Vector3(item.offset.x, 0, item.offset.y)

func remove_item_from_hand() -> void:
	item = null
	holding_item = false
	base_hand_position = Vector3(0, holding_item_y_value, 0)

func _process(delta: float) -> void:
	# Match subviewport camera to main camera
	subviewport_camera.global_transform = main_camera.global_transform
	subviewport_camera.v_offset = main_camera.v_offset / 5
	subviewport_camera.h_offset = main_camera.h_offset / 5
	subviewport_camera.fov = 150 - main_camera.fov

	if holding_item and item != null:
		position_arm(delta)

func offset_viewport_arm(mouse_offset: Vector2) -> void:
	movement_offset = mouse_offset * movement_offset_multiplier

func position_arm(delta: float) -> void:
	# Calculate new sway offset from movement
	var target_sway = Vector3(movement_offset.y, -movement_offset.x, 0)
	sway_offset = sway_offset.lerp(target_sway, 10.0 * delta)

	# Smoothly position hand with sway
	var target_position = base_hand_position + sway_offset
	hand.position = hand.position.lerp(target_position, 10.0 * delta)
