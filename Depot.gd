extends CharacterBody3D

@export var gravity: float = 120.0
@export var max_speed: float = 400.0
@export var smash_height: float = 0.5
var things_in_shake_area: Array = []

var active: bool = false

func fall_from_sky() -> void:
	active = true
	$AnimationPlayer.play("Falling")
	$MeshInstance3D.scale = Vector3.ZERO
	velocity = Vector3(0, -500, 0)

func _physics_process(delta: float) -> void:
	if not active:
		return

	velocity.y -= gravity * delta
	velocity.y = max(velocity.y, -max_speed)

	move_and_slide()

	if is_on_floor():
		impact()

func impact() -> void:
	active = false
	velocity = Vector3.ZERO
	_smash_effects()

func _smash_effects() -> void:
	for body in things_in_shake_area:
		body.add_screenshake(20)
	$AnimationPlayer.play("Impact")

func _on_smash_area_body_entered(body: Node3D) -> void:
	smash(body)

func smash(node: Node3D) -> void:
	node.queue_free()

func _on_shake_area_body_entered(body: Node3D) -> void:
	if body is Player:
		things_in_shake_area.push_front(body)

func _on_shake_area_body_exited(body: Node3D) -> void:
	if body is Player:
		things_in_shake_area.erase(body)
