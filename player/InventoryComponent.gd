extends Node

var item_preventing_movement: bool = false
var inventory_index: int = 0
@onready var parent = get_parent()
@export var inventory_size: int = 6
@onready var inventory: Array[Item] = Array([], TYPE_OBJECT, "Node3D", Item)
@onready var max_inventory_slots = inventory_size
@onready var inventory_node: Node = %hud.get_node("Hotbar/HBoxContainer")
@onready var dropray: RayCast3D = parent.head_pivot.get_node("Dropray")

func _ready() -> void:
	for i in range(inventory_size):
		inventory.append(null)
	set_hotbar_index(0)

func get_looking_at_ray():
	dropray.force_raycast_update()
	if dropray.is_colliding():
		return (dropray.get_collision_point())
	else:
		return null

func pickup_item(item: Item) -> void:
	item.position = Vector3.ZERO
	item.rotation = Vector3.ZERO
	item.thing_holding_me = parent
	item.get_node("CollisionShape3D").disabled = true
	item.get_parent().remove_child(item)
	Debug.debug("Attempting to pick up item")
	# if the player has an item, fill in next slot
	if parent.held_item != null:
		for i in range(len(inventory)):
			if inventory[i] == null:
				inventory[i] = item
				var new_slot = inventory_node.get_child(i)
				new_slot.texture = item.hotbar_texture
				new_slot.stretch_mode = TextureRect.StretchMode.STRETCH_SCALE
				Debug.debug("Picking up item in inventory")
				break
	else:
		inventory[inventory_index] = item
		var new_slot = inventory_node.get_child(inventory_index)
		new_slot.texture = item.hotbar_texture
		new_slot.stretch_mode = TextureRect.StretchMode.STRETCH_SCALE
		Debug.debug("Picking up item in hand")
	update_held_item()

func update_held_item() -> void:
	var item: Item = inventory[inventory_index]
	parent.held_item = item
	for child in parent.item_hand.get_children():
		parent.item_hand.remove_child(child)
	if item != null:
		parent.item_hand.add_child(parent.held_item)

func drop_item() -> void:
	Debug.debug("dropping item")
	# remove item from hotbar
	# remove item from players hand
	# remove item from inventory
	# drop item on ground
	# if youre holding an item
	if parent.held_item != null:
		# set item to null
		inventory[inventory_index] = null
		# remove image from hotbar
		inventory_node.get_child(inventory_index - 1).texture = null
		parent.held_item.thing_holding_me = null
		parent.held_item.get_dropped()
		# make sure its not yours anymore

		parent.held_item.get_parent().remove_child(parent.held_item)
		# fix hitboxes and positions
		parent.dropray.force_raycast_update()
		var droppoint = Vector3.ZERO
		if parent.dropray.is_colliding():
			parent.droppoint = parent.dropray.get_collision_point()
		else:
			parent.downray.target_position = Vector3(0, -200, 0)
			parent.downray.rotation.x = -parent.gameplay_head.get_node("HeadPivot").rotation.x
			parent.downray.force_raycast_update()
			if parent.downray.is_colliding():
				parent.droppoint = parent.downray.get_collision_point()
			else:
				parent.held_item.queue_free()
		if parent.held_item:
			parent.held_item.position = droppoint
			parent.held_item.get_node("CollisionShape3D").disabled = false
			var world = get_tree().get_first_node_in_group("world")
			world.get_node("Items").add_child(parent.held_item)
			parent.held_item.rotation = Vector3(0, parent.rotation.y, 0)

func set_hotbar_index(index: int) -> void:
	# 5 slots if 4 index
	var max_inventory_index = max_inventory_slots - 1
	if index > max_inventory_index:
		return
	inventory_index = index
	for slot in inventory_node.get_children():
		slot.get_node("SelectionTexture").visible = false
	inventory_node.get_child(index).get_node("SelectionTexture").visible = true
	update_held_item()

func _process(_delta) -> void:
