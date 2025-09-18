extends Item

@onready var orb = get_node("Orb")
@export var x_rotation: float
@export var z_rotation: float

func _ready() -> void:
	get_node("AnimationPlayer").play("enable")

func _process(delta: float) -> void:
	orb.rotate_x(deg_to_rad(x_rotation) * delta)
	orb.rotate_z(deg_to_rad(z_rotation) * delta)

func set_material(material: Material) -> void:
	var mesh: Mesh = orb.mesh
	mesh.surface_set_material(0, material)

func disable() -> void:
	get_node("AnimationPlayer").play("disable")

func enable() -> void:
	get_node("AnimationPlayer").play("enable")
