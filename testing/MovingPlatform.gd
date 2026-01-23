extends CharacterBody3D

var angle: float = 0.0
var speed: float = 3.0

func _physics_process(delta: float) -> void:
	angle += delta
	var dir: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
	velocity = dir * speed
	move_and_slide()
