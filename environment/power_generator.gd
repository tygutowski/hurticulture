extends Electrical

func interact() -> void:
	PowerManager.current_power += 10000

func power_outage() -> void:
	pass

func power_return() -> void:
	pass
