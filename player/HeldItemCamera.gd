extends CanvasLayer


@export var movement_offset_multiplier: float = .5
@export var ads_offset_damp: float = 0.01
@export var main_camera: Camera3D
@export var holding_item_y_value: float = 0
@export var empty_hand_y_value: float = 60

# Nodes
@onready var subviewport: SubViewport = get_node("SubViewportContainer/SubViewport")
@onready var subviewport_camera: Camera3D = subviewport.get_node("Camera3D")
@onready var right_arm: Skeleton3D = subviewport_camera.get_node("RSkeletonArm")
@onready var left_arm: Skeleton3D = subviewport_camera.get_node("LSkeletonArm")
@onready var item_hand: Node3D = right_arm.get_node("BoneAttachment3D/Hand")
@onready var pivot: Node3D = subviewport_camera.get_node("Pivot")
@onready var right_hand_target: Node3D = pivot.get_node("RHandTarget")
@onready var left_forearm_target: Node3D = pivot.get_node("LForeArmTarget")
# Values
@onready var normal_arm_position: Vector3 = right_hand_target.position

var item: Item = null
var holding_item: bool = false
var positioned_at_center: bool = false
var turn_delta: Vector2 = Vector2.ZERO
var movement_offset: Vector2 = Vector2.ZERO
var default_x: float = 0.175
var centered_x: float = 0.175
var desired_r_arm_position: Vector3 = Vector3.ZERO

func add_item_to_hand(new_item: Item) -> void:
	item = new_item

func remove_item_from_hand() -> void:
	item = null

func _process(_delta: float) -> void:
	subviewport_camera.global_transform = main_camera.global_transform
	subviewport_camera.v_offset = main_camera.v_offset/5
	subviewport_camera.h_offset = main_camera.h_offset/5
	subviewport_camera.fov = 150 - main_camera.fov
	position_arm()
	if item != null:
		if item.two_handed:
			position_secondary_arm()

func offset_viewport_arm(mouse_offset: Vector2) -> void:
	movement_offset = mouse_offset * movement_offset_multiplier

func position_arm() -> void:
	var desired_skeleton_position
	if positioned_at_center:
		desired_skeleton_position = centered_x
		desired_r_arm_position = Vector3(normal_arm_position.x, 0, 10)
	else:
		desired_skeleton_position = default_x
		desired_r_arm_position = normal_arm_position
	
	if holding_item:
		desired_r_arm_position.y -= holding_item_y_value
	else:
		desired_r_arm_position.y -= empty_hand_y_value

	right_arm.position.x = lerp(right_arm.position.x, desired_skeleton_position, 0.1)
	desired_r_arm_position += Vector3(0, movement_offset.y, -movement_offset.x)
	right_hand_target.position = lerp(right_hand_target.position, desired_r_arm_position, 0.1)

func position_secondary_arm() -> void:
	var desired_arm_position = desired_r_arm_position + item.get_secondary_hand_position()
	#desired_arm_position += Vector3(0, movement_offset.y, -movement_offset.x)
	left_forearm_target.position = lerp(left_forearm_target.position, desired_arm_position, 0.1)

func enable_ads() -> void:
	positioned_at_center = true

func disable_ads() -> void:
	positioned_at_center = false
