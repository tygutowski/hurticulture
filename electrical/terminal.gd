extends Node3D

func _process(_delta: float) -> void:
	var power_sum = PowerManager.power_sum
	if PowerManager.power_out:
		power_sum = 0
	get_node("CanvasLayer/PowerSumLabel").text = "power draw: " + str(power_sum).substr(0,5)
	get_node("CanvasLayer/CurrentPowerLabel").text = "power: " + str(int(PowerManager.current_power)) + "/" + str(PowerManager.max_power)
