extends Item

@export var spin_speed: float = 0
@export var bounce_speed: float = 0

@onready var head: Node3D = get_node("ShippingBeacon/Head")
var time: float = 0
var base_y: float

func _ready() -> void:
	$AnimationPlayer.play("RESET")
	base_y = head.position.y

func _process(delta) -> void:
	time += delta
	head.rotate_y(spin_speed * delta)
	head.position.y = base_y + sin(time * TAU) * bounce_speed - bounce_speed

func use_item() -> void:
	$AnimationPlayer.play("Enable")

func _on_picked_up() -> void:
	$AnimationPlayer.play("Disable")
