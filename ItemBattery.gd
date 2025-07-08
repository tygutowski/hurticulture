extends Item
class_name Battery

@export var max_charge: float = 100.0
@export var decay_time: float = 3600.0 # how long it takes the battery to fully decay (in seconds)

var charge: float = 0.0
var decay_rate = max_charge/decay_time

func _physics_process(delta) -> void:
	charge -= delta * decay_rate

func add_charge(delta) -> void:
	charge = max(charge + delta, max_charge)
