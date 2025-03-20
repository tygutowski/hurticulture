extends ItemUsable

var energy: int

func _ready():
	super._ready()
	print("flashlight")
	set_power(0)

func use_item() -> void:
	cycle_intensity()

func cycle_intensity():
	var new_energy = (energy + 5) % 10
	set_power(new_energy)

func set_power(value: int) -> void:
	energy = value
	$SpotLight3D.light_energy = energy
