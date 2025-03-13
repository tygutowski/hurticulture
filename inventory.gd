extends Control

var inventory_width: int = 3
var inventory_height: int = 4

var separation: int = 0

var current_slot_hovered: Vector2i = Vector2i(-1, -1)
var held_inventory_item: Control = null

@onready var columns: Control = get_node("MarginContainer/MarginContainer/MarginContainer/HBoxContainer")
@onready var inventory_slot: PackedScene = preload("res://InventorySlot.tscn")

func _ready() -> void:
	prepare_default_state()
	clear_inventory_slots()
	add_inventory_slots()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("lmb"):
		if current_slot_hovered != Vector2i(-1, -1):
			print("clicked " + str(current_slot_hovered))

func _mouse_entered(slot_index) -> void:
	current_slot_hovered = slot_index

func _mouse_exited(slot_index) -> void:
	current_slot_hovered = Vector2i(-1, -1)

func prepare_default_state() -> void:
	columns.add_theme_constant_override("separation", separation)

func add_inventory_slots() -> void:
	for i in range(inventory_width):
		var new_row: Control = VBoxContainer.new()
		new_row.add_theme_constant_override("separation", separation)
		columns.add_child(new_row)
		add_rows(new_row, i)

func add_rows(parent_node: Control, column_index: int) -> void:
	for row_index in range(inventory_height):
		var new_row: Control = inventory_slot.instantiate()
		var slot_index: Vector2i = Vector2(column_index, row_index)
		var slot_name: String = 'InventorySlot ' + str(slot_index)
		new_row.name = slot_name
		parent_node.add_child(new_row)
		new_row.mouse_entered.connect(_mouse_entered.bind(slot_index))
		new_row.mouse_exited.connect(_mouse_exited.bind(slot_index))

func clear_inventory_slots() -> void:
	for column in columns.get_children():
		column.queue_free()
