extends Node3D

var max_power : float = 99999
var current_power : float = 99999
var electrical_items : Array[Node] = []

var power_out : bool = false
var power_sum : float = 0

var has_game_started : bool = false

func start_game() -> void:
	electrical_items = get_tree().get_nodes_in_group("electrical")
	for node in electrical_items:
		assert(node is Electrical)
	has_game_started = true

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not has_game_started:
		return
	if not power_out:
		power_sum = 0
		for electrical_item in electrical_items:
			if is_on(electrical_item):
				drain(electrical_item, delta)
	if not power_out and current_power == 0:
		power_outage()
	if power_out and current_power > 0:
		power_return()

func drain(electrical_item : Node, delta: float):
	var power_consumption = electrical_item.power_consumption
	power_sum += power_consumption * delta
	current_power = clamp(current_power - power_consumption, 0, max_power)

func is_on(electrical_item : Node):
	if electrical_item.state == Electrical.ElectricalState.ON:
		return true

func power_outage():
	power_out = true
	for electrical_item in electrical_items:
		electrical_item.power_outage()

func power_return():
	power_out = false
	for electrical_item in electrical_items:
		electrical_item.power_return()
