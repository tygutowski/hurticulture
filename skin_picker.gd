extends Panel

const ROTATE_SENSITIVITY: float = 0.025
var hue: float = 0
var saturation: float = 0
var value: float = 0
@onready var color: Color = Color(0, 0, 0)
@export var final_color_color_rect: ColorRect
@export var hsv_box_color_rect: ColorRect
@onready var hsv_box_color_picker: TextureRect = hsv_box_color_rect.get_node("TextureRect")
@export var hue_bar_color_rect: ColorRect
@onready var hue_bar_color_picker: TextureRect = hue_bar_color_rect.get_node("TextureRect")
@export var viewport: SubViewport
@onready var robot: MeshInstance3D = viewport.get_node("RobotMesh")
@export var color_picker_offset: Vector2 = Vector2(0, 0)
@onready var camera_pivot: Node3D = robot.get_node("CameraPivot")
@onready var subviewport: SubViewportContainer = viewport.get_parent()
var dragging_hue: bool = false
var dragging_hsv: bool = false
var dragging_camera: bool = false
var last_mouse_pos: Vector2

var body_part_selected: int = Global.PlayerBodyPart.CHEST

func _ready() -> void:
	load_player_data()
	camera_pivot.rotate_z(deg_to_rad(15))
	set_hue(0.0)
	set_sv(0.5, 0.5)

func load_player_data() -> void:
	for body_part: int in Global.player_colors:
		var color: Color = Global.player_colors[body_part]
		pass_color_to_shader(color, body_part)
	set_player_head(Global.PlayerHeads.STEAMPUNK)

func pass_color_to_shader(color, body_part) -> void:
	var shader_material: ShaderMaterial = robot.get_surface_override_material(0)
	shader_material.set_shader_parameter("color_" + str(body_part_selected), color)

func set_hue(new_hue: float) -> void:
	hue = clamp(new_hue, 0.0, 1.0)
	hue_bar_color_picker.position.x = (hue * hue_bar_color_rect.size.x) + color_picker_offset.x
	update_color()

func set_sv(new_saturation: float, new_value: float) -> void:
	saturation = clamp(new_saturation, 0.0, 1.0)
	value = clamp(new_value, 0.0, 1.0)
	hsv_box_color_picker.position.x = saturation * hsv_box_color_rect.size.x + color_picker_offset.x
	hsv_box_color_picker.position.y = (1.0 - value) * hsv_box_color_rect.size.y + color_picker_offset.y
	update_color()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if hue_bar_color_rect.get_global_rect().has_point(event.position):
				dragging_hue = true
				update_hue_from_mouse(event.position)
			elif hsv_box_color_rect.get_global_rect().has_point(event.position):
				dragging_hsv = true
				update_saturation_value_from_mouse(event.position)
			elif subviewport.get_global_rect().has_point(event.position):
				dragging_camera = true
				last_mouse_pos = event.position
		elif event.is_released():
			dragging_hue = false
			dragging_hsv = false
			dragging_camera = false

	elif event is InputEventMouseMotion:
		if dragging_hue:
			update_hue_from_mouse(event.position)
		if dragging_hsv:
			update_saturation_value_from_mouse(event.position)
		if dragging_camera:
			pan_camera(event.position)

func pan_camera(mouse_pos: Vector2) -> void:
	var delta = mouse_pos - last_mouse_pos
	last_mouse_pos = mouse_pos
	camera_pivot.rotate_z(-delta.x * ROTATE_SENSITIVITY)

func update_hue_from_mouse(mouse_pos: Vector2) -> void:
	var rect = hue_bar_color_rect.get_global_rect()
	set_hue((mouse_pos.x - rect.position.x) / rect.size.x)

func update_saturation_value_from_mouse(mouse_pos: Vector2) -> void:
	var rect = hsv_box_color_rect.get_global_rect()
	set_sv((mouse_pos.x - rect.position.x) / rect.size.x, 1.0 - (mouse_pos.y - rect.position.y) / rect.size.y)

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
	pass_color_to_shader(color, body_part_selected)

func _on_body_part_value_changed(value: float) -> void:
	body_part_selected = value

func set_player_head(head_type) -> void:
	robot.get_child(Global.player_head_selected).visible = false
	robot.get_child(head_type).visible = true
	Global.player_head_selected = head_type

func _on_steampunk_button_pressed() -> void:
	set_player_head(Global.PlayerHeads.STEAMPUNK)

func _on_starwars_button_pressed() -> void:
	set_player_head(Global.PlayerHeads.STARWARS)

func _on_scifi_button_pressed() -> void:
	set_player_head(Global.PlayerHeads.SCIFI)

func _on_cyberpunk_button_pressed() -> void:
	set_player_head(Global.PlayerHeads.CYBERPUNK)
