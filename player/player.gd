class_name Player
extends CharacterBody3D

var mouse_sensitivity = 0.3
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var is_holding : bool = false

@onready var dropray: RayCast3D = $Head/RayCast3D
@onready var downray: RayCast3D = $Head/RayCast3D/DownRay

var held_item = null

@onready var head = get_node("Head")
@onready var pause_menu = get_node("pausemenu")
@onready var timer = get_node("Timer")

var pullback_time : float = 0.0
var max_pullback_time : float = 2.0

var can_interact : bool = true

@onready var inventory: Array[Item] = [null, null, null, null]
var inventory_index: int = 0
@onready var hotbar: Node = %hud.get_node("MarginContainer/HBoxContainer")

func _ready() -> void:
	set_inventory_index(0)
	head.get_node("Camera3D").fov = Settings.fov
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func interact() -> void:
	print("you can not interact now")
	can_interact = false
	timer.start()

func pickup_item(item: Item) -> void:
	item.position = Vector3.ZERO
	item.rotation = Vector3.ZERO
	item.get_node("CollisionShape3D").disabled = true
	item.get_parent().remove_child(item)
	print("Attempting to pick up item")
	# if the player has an item, fill in next slot
	if held_item != null:
		for i in range(len(inventory) - 1):
			inventory[i] = item
			var new_slot = hotbar.get_child(i)
			new_slot.get_node("SlotTexture").texture = item.slot_texture
			print("Picking up item in inventory")
	else:
		inventory[inventory_index] = item
		var new_slot = hotbar.get_child(inventory_index)
		new_slot.get_node("SlotTexture").texture = item.slot_texture
		print("Picking up item in hand")
	update_held_item()

func drop_it() -> void:
	# if youre holding an item
	if held_item != null:
		# make sure its not yours anymore
		inventory[inventory_index] = null
		held_item.get_parent().remove_child(held_item)
		
		# fix hitboxes and positions
		dropray.force_raycast_update()
		var droppoint = Vector3.ZERO
		if dropray.is_colliding():
			droppoint = dropray.get_collision_point()
		else:
			downray.target_position = Vector3(0, -200, 0)
			downray.rotation.x = -head.rotation.x
			downray.force_raycast_update()
			if downray.is_colliding():
				droppoint = downray.get_collision_point()
			else:
				held_item.queue_free()
		if held_item:
			held_item.position = droppoint
			held_item.get_node("CollisionShape3D").disabled = false
			var world = get_tree().get_first_node_in_group("world")
			world.get_node("Items").add_child(held_item)
		update_held_item()

func update_held_item() -> void:
	var item: Item = inventory[inventory_index]
	held_item = item
	for child in get_node("Head/ItemHand").get_children():
		get_node("Head/ItemHand").remove_child(child)
	if item != null:
		get_node("Head/ItemHand").add_child(held_item)

func hold_item(item : Node3D) -> void:
	print("holding item")
	if not is_holding and can_interact:
		interact()
		held_item = item
		held_item.is_being_held = true
		is_holding = true

func drop_item() -> void:
	print("drop item")
	if is_holding and can_interact:
		interact()
		held_item.is_being_held = false
		is_holding = false

func set_inventory_index(index: int) -> void:
	inventory_index = index
	for slot in hotbar.get_children():
		slot.get_node("SelectionTexture").visible = false
	hotbar.get_child(index).get_node("SelectionTexture").visible = true
	update_held_item()

func _physics_process(delta: float) -> void:
	if is_holding and can_interact:
		if Input.is_action_just_pressed("interact"):
			drop_item()
		if Input.is_action_pressed("lmb"):
			pullback_time = clamp(0, pullback_time + delta, max_pullback_time)
		else:
			if pullback_time != 0:
				held_item.throw(pullback_time)
				drop_item()
			pullback_time = 0
		
	if not is_on_floor():
		velocity += get_gravity() * delta

	if held_item != null:
		if Input.is_action_just_pressed("drop"):
			drop_it()
		if Input.is_action_just_pressed("lmb"):
			held_item.use_item()
		elif Input.is_action_just_pressed("rmb"):
			held_item.alt_use_item()
		elif Input.is_action_just_pressed("reload"):
			held_item.reload_item()
	
	if Input.is_action_just_pressed("scroll_down"):
		set_inventory_index((inventory_index + 1) % 4)
	elif Input.is_action_just_pressed("scroll_up"):
		set_inventory_index((inventory_index - 1) % 4)
	elif Input.is_action_just_pressed("hotbar_one"):
		set_inventory_index(0)
	elif Input.is_action_just_pressed("hotbar_two"):
		set_inventory_index(1)
	elif Input.is_action_just_pressed("hotbar_three"):
		set_inventory_index(2)
	elif Input.is_action_just_pressed("hotbar_four"):
		set_inventory_index(3)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_just_pressed("pause"):
		pause_menu.toggle_pause_menu()
	
	var input_dir := Input.get_vector("left", "right", "forward", "backwards")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var run_scalar = 1.0 + float(Input.is_action_pressed("run"))/2
	if direction:
		velocity.x = direction.x * SPEED * run_scalar
		velocity.z = direction.z * SPEED * run_scalar
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * deg_to_rad(mouse_sensitivity))
		head.rotate_x(-event.relative.y * deg_to_rad(mouse_sensitivity))
		head.rotation.x = clampf(head.rotation.x, -deg_to_rad(85), deg_to_rad(85))


func _on_timer_timeout() -> void:
	print("you can interact now")
	can_interact = true
