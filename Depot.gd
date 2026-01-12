extends CharacterBody3D

@export var max_speed: float = 400.0
var things_in_shake_area: Array = []
var state: States = States.FALLING

var liftoff_time: float = 0.0
@export var thrust: float = 120.0
@export var pitch_rate_deg: float = 8.0
@export var vertical_hold_time: float = 0.6

enum States {
	FALLING,
	GROUNDED,
	COUNTDOWN,
	LIFTOFF
}

# called from Beacon.gd
func fall_from_sky() -> void:
	rotate_x(randf_range(deg_to_rad(1),deg_to_rad(2)))
	rotate_y(randf_range(0, 2*PI))
	state = States.FALLING
	$AnimationPlayer.play("Falling")
	velocity = -global_transform.basis.y.normalized() * 400

func _physics_process(delta: float) -> void:
	print("state: " + str(state) + ", velocity.y: " + str(velocity.y))
	if state == States.GROUNDED:
		velocity.y = 0
	elif state == States.FALLING:
		var fall_dir: Vector3 = -global_transform.basis.y.normalized()
		velocity += fall_dir * get_gravity().y * delta
		if is_on_floor():
			impact()
	elif state == States.LIFTOFF:
		liftoff_time += delta

		# 1. Rotate AFTER initial vertical burn
		if liftoff_time > vertical_hold_time:
			var pitch_delta: float = deg_to_rad(pitch_rate_deg) * delta
			rotate_z(pitch_delta) # choose axis based on model orientation

		# 2. Thrust along local up (rocket-style)
		var thrust_dir: Vector3 = global_transform.basis.y.normalized()
		velocity += thrust_dir * thrust * delta

		# 3. Optional thrust ramp (feels more real)
		var ramp: float = clamp(liftoff_time / 0.5, 0.0, 1.0)
		velocity *= lerp(1.0, 1.01, ramp)

	move_and_slide()

func jump() -> void:
	velocity.y += 50

func impact() -> void:
	state = States.GROUNDED
	velocity = Vector3.ZERO
	$AnimationPlayer.play("Impact")
	
	for body in things_in_shake_area:
		body.add_screenshake(20)

func countdown() -> void:
	print('countdown')
	state = States.COUNTDOWN
	$AnimationPlayer.play("Countdown")

func liftoff() -> void:
	print('liftoff')
	state = States.LIFTOFF
	$AnimationPlayer.play("Liftoff")

func _on_smash_area_body_entered(body: Node3D) -> void:
	smash(body)

# kills things in the smash area
func smash(node: Node3D) -> void:
	node.queue_free()

func _on_shake_area_body_entered(body: Node3D) -> void:
	if body is Player:
		things_in_shake_area.push_front(body)

func _on_shake_area_body_exited(body: Node3D) -> void:
	if body is Player:
		things_in_shake_area.erase(body)
