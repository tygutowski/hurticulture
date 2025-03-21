extends Control

var inventory: Array[Array] = []

var slot_picked_up_from: Vector2i = Vector2i.ZERO
var inventory_width: int = 4
var inventory_height: int = 3
var mouse_offset = Vector2(32,32)
var separation: int = 0

@onready var selected_shader = preload("res://HoveredOutlineShader.tres")
@onready var default_slot_texture: Texture = preload("res://InventorySlot.png")
@onready var selected_slot_texture: Texture = preload("res://InventorySlotDark.png")

var current_slot_hovered: Vector2i = Vector2i(-1, -1)

# inventory item that is held with mouse, NOT in the player's hand.
var held_inventory_item: Item = null
#var held_inventory_control_node: Control = null

@onready var columns: Control = get_node("MarginContainer/MarginContainer/MarginContainer/HBoxContainer")
@onready var inventory_slot: PackedScene = preload("res://InventorySlot.tscn")

func _ready() -> void:
	var flashlight: Item = preload("res://environment/items/tools/ItemFlashlight.tscn").instantiate()
	await flashlight._ready()
	var moonfruit: Item = preload("res://environment/items/fruits/ItemMoonFruit.tscn").instantiate()
	await moonfruit._ready()

	prepare_default_state()
	clear_inventory_slots()
	add_inventory_slots()
	put_item(flashlight, Vector2i(1, 1), true)
	put_item(moonfruit, Vector2i(2, 2), true)
	#var item3: Item = load("res://environment/items/tools/ItemSeedPacket.tscn").instantiate()
	#place_item_in_slot(item3, Vector2i(2, 1))

func put_item(item: Item, root_slot: Vector2i, debug: bool = false):
	var offset = item.slot - slot_picked_up_from
	root_slot += offset
	
	for slot in item.occupying_slots:
		slot = root_slot + slot
		if slot.x < 0 or slot.y < 0 or slot.x >= inventory_width or slot.y >= inventory_height:
			print("slot out of bounds")
			return
		if inventory[slot.x][slot.y] != null:
			print("slot already occupied")
			return
	
	for slot in item.occupying_slots:
		slot = root_slot + slot
		inventory[slot.x][slot.y] = item
	item.slot = root_slot
	
	set_held_inventory_item(null)
	set_slot_texture(item.slot, item.inventory_texture)
	if not debug:
		add_item_outline(item.slot)

func set_slot_texture(slot: Vector2i, texture: Texture) -> void:
	columns.get_child(slot.x).get_child(slot.y).get_node("SlotContents").texture = texture


func pick_item(slot: Vector2i) -> void:
	remove_item_outline(slot)
	if inventory[slot.x][slot.y] == null:
		return
	
	var item: Item = inventory[slot.x][slot.y]
	for occupied_slot in item.occupying_slots:
		var actual_slot = item.slot + occupied_slot
		inventory[actual_slot.x][actual_slot.y] = null
	
	slot_picked_up_from = slot
	set_slot_texture(item.slot, null)
	set_held_inventory_item(item)

func set_held_inventory_item_position() -> void:
	if held_inventory_item != null:
		var slot_offset: Vector2 = Vector2(held_inventory_item.slot) - Vector2(slot_picked_up_from)
		$HeldItem.position = get_viewport().get_mouse_position() - mouse_offset + (slot_offset * Global.INVENTORY_SLOT_SIZE)

func set_held_inventory_item(item: Item) -> void:
	held_inventory_item = item
	if held_inventory_item == null:
		$HeldItem.texture = null
	else:
		if held_inventory_item.inventory_texture != null:
			$HeldItem.texture = held_inventory_item.inventory_texture
	set_held_inventory_item_position()

func _process(_delta: float) -> void:
	set_held_inventory_item_position()
	if Input.is_action_just_pressed("lmb"):
		# if holding nothing
		if held_inventory_item == null:
			# and click on slot
			if current_slot_hovered != Vector2i(-1, -1):
				# and slot has item
				if inventory[current_slot_hovered.x][current_slot_hovered.y] != null:
					pick_item(current_slot_hovered)
		# if holding item
		else:
			# display item in cursor
			# and click on slot
			if current_slot_hovered != Vector2i(-1, -1):
				# and slot is empty
				if inventory[current_slot_hovered.x][current_slot_hovered.y] == null:
					# put item into slot
					var corrected_root = current_slot_hovered - slot_picked_up_from  # Adjust placement to align correctly
					put_item(held_inventory_item, current_slot_hovered)

func darken_slot(slot_index) -> void:
	columns.get_child(slot_index.x).get_child(slot_index.y).texture = selected_slot_texture

func lighten_slot(slot_index) -> void:
	columns.get_child(slot_index.x).get_child(slot_index.y).texture = default_slot_texture

func add_item_outline(slot_index) -> void:
	if held_inventory_item == null:
		var item = inventory[slot_index.x][slot_index.y]
		if item != null:
			columns.get_child(item.slot.x).get_child(item.slot.y).get_child(0).material = selected_shader

func _mouse_entered(slot_index) -> void:
	add_item_outline(slot_index)
	darken_slot(slot_index)
	current_slot_hovered = slot_index

func remove_item_outline(slot_index) -> void:
	if held_inventory_item == null:
		var item = inventory[slot_index.x][slot_index.y]
		if item != null:
			columns.get_child(item.slot.x).get_child(item.slot.y).get_child(0).material = null

func _mouse_exited(slot_index) -> void:
	remove_item_outline(slot_index)

	lighten_slot(slot_index)
	current_slot_hovered = Vector2i(-1, -1)

func prepare_default_state() -> void:
	columns.add_theme_constant_override("separation", separation)

func add_inventory_slots() -> void:
	inventory = []
	for column_index in range(inventory_width):
		var new_column: Control = VBoxContainer.new()
		new_column.add_theme_constant_override("separation", separation)
		columns.add_child(new_column)
		var inventory_column = []
		for row_index in range(inventory_height):
			inventory_column.append(null)
			var new_row: Control = inventory_slot.instantiate()
			var slot_index: Vector2i = Vector2(column_index, row_index)
			var slot_name: String = 'InventorySlot ' + str(slot_index)
			new_row.name = slot_name
			new_column.add_child(new_row)
			new_row.mouse_entered.connect(_mouse_entered.bind(slot_index))
			new_row.mouse_exited.connect(_mouse_exited.bind(slot_index))
		inventory.append(inventory_column)

func clear_inventory_slots() -> void:
	for column in columns.get_children():
		columns.remove_child(column)
		column.queue_free()
