class_name Player
extends CharacterBody3D

var mouse_sensitivity = 0.3
const JUMP_VELOCITY = 4.5
var is_holding : bool = false
var inventory_open: bool = false
const ACCELERATION : float = 10
const FRICTION : float = 12

var head_rotation : Vector3 = Vector3.ZERO
var increment_progress_bar: bool = false
var item_preventing_movement: bool = false
@onready var inventory: Control = $hud/Inventory
@onready var dropray: RayCast3D = $Head/RayCast3D
@onready var downray: RayCast3D = $Head/RayCast3D/DownRay

var held_item: Item = null

@onready var head = get_node("Head")
@onready var pause_menu = get_node("pausemenu")
@onready var timer = get_node("Timer")

const WALK_SPEED : float = 3
const RUN_SPEED : float = 5
var pullback_time : float = 0.0
var max_pullback_time : float = 2.0

var can_interact : bool = true

var hotbar_index: int = 0
@onready var hotbar: Node = %hud.get_node("Hotbar/HBoxContainer")

func _ready() -> void:
	set_inventory_visible(false)
	set_hotbar_index(0)
	head.get_node("Camera3D").fov = Settings.fov
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func interact() -> void:
	Debug.debug("you can not interact now")
	can_interact = false
	timer.start()

func pickup_item(item: Item) -> void:
	item.position = Vector3.ZERO
	item.rotation = Vector3.ZERO
	item.get_node("CollisionShape3D").disabled = true
	item.get_parent().remove_child(item)
	item.get_picked_up_by(self)
	Debug.debug("Attempting to pick up item")
	# if the player has an item, fill in next slot

func get_looking_at_ray():
	dropray.force_raycast_update()
	if dropray.is_colliding():
		return (dropray.get_collision_point())
	else:
		return null

func drop_it() -> void:
	# if youre holding an item
	if held_item != null:
		held_item.get_dropped()
		# make sure its not yours anymore

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
			held_item.rotation = Vector3(0, rotation.y, 0)

func hold_item(item : Node3D) -> void:
	Debug.debug("holding item")
	if not is_holding and can_interact:
		interact()
		held_item = item
		held_item.is_being_held = true
		is_holding = true

func drop_item() -> void:
	Debug.debug("drop item")
	if is_holding and can_interact:
		interact()
		held_item.is_being_held = false
		is_holding = false

func set_inventory_visible(value: bool) -> void:
	inventory.visible = value
	inventory_open = value

func toggle_inventory_visibility() -> void:
	set_inventory_visible(not inventory_open)

func set_hotbar_index(index: int) -> void:
	hotbar_index = index
	for slot in hotbar.get_children():
		slot.get_node("SelectionTexture").visible = false
	hotbar.get_child(index).get_node("SelectionTexture").visible = true

func _physics_process(delta: float) -> void:
	if held_item != null and increment_progress_bar:
		var diff = 100.0/held_item.hold_duration * delta
		$hud/TextureProgressBar.value += diff
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
		if held_item.held_down_item: # if its an item you must hold down to use
			if Input.is_action_just_released("lmb"):
				held_item.stop_using_item()
			if Input.is_action_just_pressed("lmb"):
				held_item.begin_using_item()
		else: # if its an item you click to use
			if Input.is_action_just_pressed("lmb"):
				held_item.use_item()
		if Input.is_action_just_pressed("drop"):
			drop_it()
		elif Input.is_action_just_pressed("reload"):
			held_item.reload_item()
	
	if Input.is_action_just_pressed("scroll_down"):
		set_hotbar_index((hotbar_index + 1) % 4)
	elif Input.is_action_just_pressed("scroll_up"):
		set_hotbar_index((hotbar_index - 1) % 4)
	elif Input.is_action_just_pressed("hotbar_one"):
		set_hotbar_index(0)
	elif Input.is_action_just_pressed("hotbar_two"):
		set_hotbar_index(1)
	elif Input.is_action_just_pressed("hotbar_three"):
		set_hotbar_index(2)
	elif Input.is_action_just_pressed("hotbar_four"):
		set_hotbar_index(3)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_just_pressed("pause"):
		pause_menu.toggle_pause_menu()
	var input_dir := Input.get_vector("left", "right", "forward", "backwards")
	if held_item != null and not held_item.can_move_while_using and held_item.using_item:
		input_dir = Vector2.ZERO
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if input_dir.x != 0:
		# Interpolate rotation to the target angle
		$Head/Camera3D.rotation.z = lerp($Head/Camera3D.rotation.z, round(input_dir.x) * deg_to_rad(-1.5), .2)
	else:
		# Interpolate back to the neutral position (0 rotation)
		$Head/Camera3D.rotation.z = lerp($Head/Camera3D.rotation.z, 0.0, 0.2)
	var movement_speed = WALK_SPEED
	if Input.is_action_pressed("run") and input_dir.y < 0:
		movement_speed = RUN_SPEED
		$Head/Camera3D.fov = lerp($Head/Camera3D.fov, float(Settings.fov + 10), 0.2)
	else:
		$Head/Camera3D.fov = lerp($Head/Camera3D.fov, float(Settings.fov), 0.2)
	get_node("MeshAndAnimation/AnimationTree")["parameters/WalkSpeed/blend_position"] = Vector2(velocity.x, velocity.z).length()
	#get_node("MeshAndAnimation/RobotAnimated/AnimationTree")["parameters/WalkDirection/blend_position"] = Vector2(velocity.x, velocity.z)

	if input_dir != Vector2.ZERO:
		$Head/Camera3D.v_offset = lerp($Head/Camera3D.v_offset, sin(Time.get_unix_time_from_system()*3 * movement_speed)/48 * movement_speed, 0.2)
	else:
		$Head/Camera3D.v_offset = lerp($Head/Camera3D.v_offset, 0.0, 0.2)
	Debug.debug(direction)
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * movement_speed, ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, direction.z * movement_speed, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		velocity.z = move_toward(velocity.z, 0, FRICTION * delta)

	#if not Engine.is_editor_hint():
	#	debug_biome_weights()
	move_and_slide()

func debug_biome_weights() -> void:
	var output = ""
	for biome: Biome in get_tree().get_first_node_in_group("world").get_node("WorldGenerator").biome_list:
		output += str(biome.weightmap[int(position.z)][int(position.x)]) + ", "
	Debug.debug(output)

func _input(event):
	if not (held_item != null and not held_item.can_move_while_using and held_item.using_item):
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			# rotate player body left/right
			rotate_y(-event.relative.x * deg_to_rad(mouse_sensitivity))
			# rotate head up and down
			head.rotate_x(-event.relative.y * deg_to_rad(mouse_sensitivity))
			# clamp the rotation so you can only look so far up/down
			head.rotation.x = clampf(head.rotation.x, -deg_to_rad(85), deg_to_rad(85))

func _on_timer_timeout() -> void:
	Debug.debug("you can interact now")
	can_interact = true
