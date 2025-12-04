extends Node
class_name GameManager

var time: float = 600.0
var day_length: float = 1200.0

@onready var world: Node = get_tree().get_first_node_in_group("world")
@onready var env: WorldEnvironment = world.get_node("WorldEnvironment")
@onready var sun: DirectionalLight3D = world.get_node("MapGenerator/DirectionalLight3D")

func _process(delta: float) -> void:
	time += delta
	handle_day_cycle()

func handle_day_cycle() -> void:
	var t: float = fposmod(time / day_length, 1.0)

	var day_amount: float = 0.5 - 0.5 * cos(TAU * t)
	env.environment.background_energy_multiplier = day_amount  # 0 = black, 1 = white (you tune this)
	sun.light_energy = day_amount    # 0 = night, 1 = day
	sun.rotation_degrees.x = lerp(-90.0, 90.0, t)

func set_time(new_time: int) -> void:
	Debug.debug("Game time set to " + str(new_time))
	time = new_time
