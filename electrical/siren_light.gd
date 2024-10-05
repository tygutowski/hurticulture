extends Electrical

@onready var pivot = get_node("Pivot")
@onready var light = get_node("LightMesh")
@onready var on_texture = load("res://environment/materials/sirenlight_on.tres")
@onready var off_texture = load("res://environment/materials/sirenlight_off.tres")

@onready var spotlight1 = get_node("Pivot/SpotLight3D")
@onready var spotlight2 = get_node("Pivot/SpotLight3D2")
var default_energy = 20

var on : bool = false

func _ready():
	power_return()

func power_outage() -> void:
	on = true
	light.set_surface_override_material(0, on_texture)
	spotlight1.light_energy = default_energy
	spotlight2.light_energy = default_energy

func power_return() -> void:
	on = false
	light.set_surface_override_material(0, off_texture)
	spotlight1.light_energy = 0
	spotlight2.light_energy = 0

func _process(_delta : float) -> void:
	if on:
		pivot.rotate_y(deg_to_rad(5))
