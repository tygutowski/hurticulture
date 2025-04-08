extends CanvasLayer

@export var main_camera: Camera3D
@onready var item_hand: Node3D = $SubViewportContainer/SubViewport/Camera3D/Skeleton3D/BoneAttachment3D/HandPivot
@onready var subviewport_camera: Camera3D = $SubViewportContainer/SubViewport/Camera3D
var positioned_at_center: bool = false
@onready var pivot: Node3D = get_node("SubViewportContainer/SubViewport/Camera3D/Pivot")
@onready var target_arm: Node3D = pivot.get_node("RArmTarget")
@onready var normal_arm_position: Vector3 = target_arm.position
var turn_delta: Vector2 = Vector2.ZERO
@export var movement_offset_multiplier: float = .5
@export var ads_offset_damp: float = 0.01
var movement_offset: Vector2 = Vector2.ZERO

func _process(_delta: float) -> void:
	subviewport_camera.global_transform = main_camera.global_transform
	subviewport_camera.v_offset = main_camera.v_offset/5
	subviewport_camera.h_offset = main_camera.h_offset/5
	subviewport_camera.fov = 150 - main_camera.fov
	if positioned_at_center:
		position_at_center()
	else:
		position_at_normal_angle()

func offset_viewport_arm(mouse_offset: Vector2) -> void:
	movement_offset = mouse_offset * movement_offset_multiplier

func position_at_normal_angle() -> void:
	var desired_arm_position = normal_arm_position
	desired_arm_position += Vector3(0, movement_offset.y, -movement_offset.x)
	target_arm.position = lerp(target_arm.position, desired_arm_position, .1)

func position_at_center() -> void:
	var desired_arm_position = Vector3(normal_arm_position.x, 0, 0)
	desired_arm_position += Vector3(0, movement_offset.y, -movement_offset.x)
	target_arm.position = lerp(target_arm.position, desired_arm_position, .1)

func enable_ads() -> void:
	positioned_at_center = true

func disable_ads() -> void:
	positioned_at_center = false
