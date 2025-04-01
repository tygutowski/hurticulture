extends Node3D
class_name SkinPicker

const ROTATE_SENSITIVITY: float = 0.025

var hue: float = 0
var saturation: float = 0
var value: float = 0

@export var color_picker_offset: Vector2 = Vector2(0, 0)
@export var mouse_offset: Vector2 = Vector2(0, 0)
@onready var subviewport: SubViewport = get_node("SubViewport")
@onready var subsubviewport: SubViewport = %SubSubViewport

@onready var hsv_box_color_rect: ColorRect = %HSVColorRect
@onready var hue_bar_color_rect: ColorRect = %HueBar

@onready var color: Color = Color(0, 0, 0)
@onready var hsv_box_color_picker: TextureRect = hsv_box_color_rect.get_node("TextureRect")
@onready var hue_bar_color_picker: TextureRect = hue_bar_color_rect.get_node("TextureRect")
@onready var robot: MeshInstance3D = subsubviewport.get_node("RobotMesh")
@onready var camera_pivot: Node3D = robot.get_node("CameraPivot")
@onready var cursor = subviewport.get_node("Cursor")

var dragging_hue: bool = false
var dragging_hsv: bool = false
var dragging_camera: bool = false
var last_mouse_pos: Vector2
var body_part_selected: int = Global.PlayerBodyPart.HYDRAULICS

func _ready() -> void:
	camera_pivot.rotate_z(deg_to_rad(15))
	set_hue(0.0)
	set_sv(1.0, 1.0)

func mouse_outside_area() -> void:
	dragging_hue = false
	dragging_hsv = false
	dragging_camera = false

# changes TV screen head and changes the player's head
func set_player_head(player: CharacterBody3D, new_head: Global.PlayerHeads) -> void:
	for head in player.animation_head.get_children():
		head.visible = false
	player.animation_head.get_child(new_head).visible = true
	robot.get_child(player.gamestate.head_type).visible = false
	player.gamestate.head_type = new_head
	robot.get_child(player.gamestate.head_type).visible = true


func set_hue(new_hue: float) -> void:
	hue = clamp(new_hue, 0.0, 1.0)
	hue_bar_color_picker.position.x = (hue * hue_bar_color_rect.size.x) + color_picker_offset.x

func set_sv(new_saturation: float, new_value: float) -> void:
	saturation = clamp(new_saturation, 0.0, 1.0)
	value = clamp(new_value, 0.0, 1.0)
	hsv_box_color_picker.position.x = saturation * hsv_box_color_rect.size.x + color_picker_offset.x
	hsv_box_color_picker.position.y = (1.0 - value) * hsv_box_color_rect.size.y + color_picker_offset.y

func input(event, pos):
	cursor.position = pos + mouse_offset
	if event is InputEventMouseButton:
		event.position = pos
		if event.pressed:
			if hue_bar_color_rect.get_global_rect().has_point(pos):
				dragging_hue = true
				update_hue_from_mouse(pos)
			elif hsv_box_color_rect.get_global_rect().has_point(pos):
				dragging_hsv = true
				update_saturation_value_from_mouse(pos)
			elif subsubviewport.get_parent().get_global_rect().has_point(pos):
				dragging_camera = true
				last_mouse_pos = pos
		elif event.is_released():
			dragging_hue = false
			dragging_hsv = false
			dragging_camera = false

	elif event is InputEventMouseMotion:
		event.position = pos
		if dragging_hue:
			update_hue_from_mouse(pos)
		if dragging_hsv:
			update_saturation_value_from_mouse(pos)
		if dragging_camera:
			pan_camera(pos)

	subviewport.push_input(event)

func pan_camera(mouse_pos: Vector2) -> void:
	var delta = mouse_pos - last_mouse_pos
	last_mouse_pos = mouse_pos
	camera_pivot.rotate_z(-delta.x * ROTATE_SENSITIVITY)

func update_hue_from_mouse(mouse_pos: Vector2) -> void:
	var rect = hue_bar_color_rect.get_global_rect()
	set_hue((mouse_pos.x - rect.position.x) / rect.size.x)
	update_color()
	
func update_saturation_value_from_mouse(mouse_pos: Vector2) -> void:
	var rect = hsv_box_color_rect.get_global_rect()
	set_sv((mouse_pos.x - rect.position.x) / rect.size.x, 1.0 - (mouse_pos.y - rect.position.y) / rect.size.y)
	update_color()

func update_color() -> void:
	color.h = hue
	color.s = saturation
	color.v = value
	set_hsv_box_color()
	var player = get_tree().get_first_node_in_group("player")
	player.set_bodypart_color(color, body_part_selected)

func set_hsv_box_color() -> void:
	var shader_material: ShaderMaterial = hsv_box_color_rect.material
	shader_material.set_shader_parameter("hue", hue)

func _on_body_part_value_changed(value: float) -> void:
	body_part_selected = value

func _on_steampunk_button_pressed() -> void:
	set_player_head(get_tree().get_first_node_in_group("player"), Global.PlayerHeads.STEAMPUNK)

func _on_starwars_button_pressed() -> void:
	set_player_head(get_tree().get_first_node_in_group("player"), Global.PlayerHeads.STARWARS)

func _on_scifi_button_pressed() -> void:
	set_player_head(get_tree().get_first_node_in_group("player"), Global.PlayerHeads.SCIFI)

func _on_cyberpunk_button_pressed() -> void:
	set_player_head(get_tree().get_first_node_in_group("player"), Global.PlayerHeads.CYBERPUNK)
