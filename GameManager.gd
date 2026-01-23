extends Node
class_name GameManager

var time: float = 600.0
var day_length: float = 1200.0

@export var world: Node
@export var env: WorldEnvironment
@export var sun: DirectionalLight3D

func _process(delta: float) -> void:
	time += delta
	handle_day_cycle()

func handle_day_cycle() -> void:
	var t: float = fposmod(time / day_length, 1.0)

	var day_amount: float = 0.5 - 0.5 * cos(TAU * t)
	env.environment.background_energy_multiplier = day_amount
	sun.light_energy = day_amount
	env.environment.fog_light_energy = day_amount
	var axis: Vector3 = Vector3(1.0, 0.0, 0.3).normalized()
	var angle_rad: float = cos(TAU * t) * deg_to_rad(90.0)

	sun.transform.basis = Basis(axis, angle_rad)

func set_time(new_time: int) -> void:
	Debug.debug("Game time set to " + str(new_time))
	time = new_time
