extends ItemSnappable
class_name Battery

var charge: float = 0.0
var max_charge: float = 100.0
var decay_rate: float = 60.0 # how long it takes the battery to fully decay (in minutes)

func _physics_process(delta) -> void:
	pass

func add_charge(delta) -> void:
	charge = max(charge + delta, max_charge)
