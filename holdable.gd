class_name Holdable
extends RigidBody3D

var is_being_held : bool = false
var lerp_speed : float = 30000
var on_pickup_cooldown : bool = true
var pickup_timer : float = 0
var pickup_time : float = 0.5
var drop_distance : float = 3.0

@onready var player = get_tree().get_first_node_in_group("player")
@onready var hand = player.get_node("Head/Hand")

func _physics_process(delta : float) -> void:
	if is_being_held:
		var target_position = hand.global_transform.origin
		var current_position = global_transform.origin
		var distance = current_position.distance_to(target_position)
		var distance_to_player = current_position.distance_to(player.get_node("Head").global_transform.origin)
		if distance_to_player > drop_distance:
			player.drop_item()
		var speed = lerp_speed * delta
		var direction = current_position.direction_to(target_position)
		linear_velocity = Vector3.ZERO
		apply_central_force(direction * speed * distance)
		gravity_scale = 0
	else:
		gravity_scale = 1

func throw(pullback_time : float):
	var head = player.get_node("Head")
	var target_position = hand.global_transform.origin
	var current_position = head.global_transform.origin
	var speed = 10 * pullback_time
	var direction = current_position.direction_to(target_position)
	apply_impulse(direction * speed)

func get_dropped() -> void:
	if player.held_item == self:
		player.drop_item()
