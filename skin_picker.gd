@tool
extends Panel

var hue: float = 0
var saturation: float = 0
var value: float = 0
@onready var color: Color = Color(0, 0, 0)
@export var final_color_color_rect: ColorRect
@export var hsv_box_color_rect: ColorRect

@export var viewport: SubViewport
@onready var robot: MeshInstance3D = viewport.get_node("RobotMesh")

func _on_hue_value_changed(new_value: float) -> void:
	hue = new_value
	update_color()

func _on_saturation_value_changed(new_value: float) -> void:
	saturation = new_value
	update_color()

func _on_value_value_changed(new_value: float) -> void:
	value = new_value
	update_color()

func update_color() -> void:
	color.h = hue
	color.s = saturation
	color.v = value
	final_color_color_rect.color = color
	set_hsv_box_color()
	set_robot_armor_color()

func set_hsv_box_color() -> void:
	var shader_material: ShaderMaterial = hsv_box_color_rect.material
	shader_material.set_shader_parameter("hue", hue)

func set_robot_armor_color() -> void:
	var shader_material: ShaderMaterial = robot.get_surface_override_material(0)
	shader_material.set_shader_parameter("color_1", color)
