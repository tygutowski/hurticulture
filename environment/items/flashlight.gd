extends Item

var energy 

func _ready():
	energy = $SpotLight3D.light_energy
	set_power(false)

func use_item() -> void:
	cycle_intensity()

func cycle_intensity():
	energy = fmod((energy + 1.0), 3.0)
	$SpotLight3D.light_energy = energy

func set_power(value: bool) -> void:
	$SpotLight3D.light_energy = 0
