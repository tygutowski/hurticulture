extends Item

@export var spin_speed: float = 0
@export var bounce_speed: float = 0
@export var depot_scene: PackedScene
@onready var head: Node3D = get_node("ShippingBeacon/Head")
var time: float = 0
var base_y: float
@export var scanning: bool = false

func _ready() -> void:
	$AnimationPlayer.play("RESET")
	base_y = head.position.y

func _process(delta) -> void:
	if scanning:
		get_node("Laser/RayCast3D").force_raycast_update()
		if get_node("Laser/RayCast3D").is_colliding():
			$AnimationPlayer.play("Error")
			
	time += delta
	head.rotate_y(spin_speed * delta)
	head.position.y = base_y + sin(time * TAU) * bounce_speed - bounce_speed

func _on_picked_up() -> void:
	$AnimationPlayer.play("Disable")

func deployed() -> void:
	get_node("Laser/RayCast3D").force_raycast_update()
	if get_node("Laser/RayCast3D").is_colliding():
		$AnimationPlayer.play("Error")
	else:
		$AnimationPlayer.play("Enable")
		
func summon_depot() -> void:
	var depot: Node3D = depot_scene.instantiate()
	get_tree().current_scene.add_child(depot)

	depot.global_position = global_position + Vector3(0.0, 500.0, 0.0)
	depot.fall_from_sky()
