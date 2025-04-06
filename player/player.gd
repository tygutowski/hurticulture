class_name Player
extends CharacterBody3D



var mouse_sensitivity = 0.3
const JUMP_VELOCITY = 5
const ACCELERATION : float = 13
const FRICTION : float = 14
const MAX_HEAD_TURN_ANGLE: float = 25
var increment_progress_bar: bool = false
var item_preventing_movement: bool = false
var rotational_offset: float = 0

@export var robot_eye_material: ShaderMaterial = null
@export var robot_armor_shader: ShaderMaterial = null

@onready var head = get_node("Head")
@onready var animation_head = head.get_node("BoneAttachment3D/HeadAnimation")
@onready var gameplay_head = head.get_node("HeadGameplay")
@onready var head_pivot: Node3D = gameplay_head.get_node("HeadPivot")
@onready var dropray: RayCast3D = head_pivot.get_node("Dropray")
@onready var interactray: RayCast3D = head_pivot.get_node("InteractRay")
@onready var computerray: RayCast3D = head_pivot.get_node("ComputerRay")
@onready var downray: RayCast3D = dropray.get_node("DownRay")
var held_item: Item = null
var feet_stance_angle: float = 0
@onready var camera = gameplay_head.get_node("HeadPivot/Camera3D")
@onready var pause_menu = get_node("pausemenu")

@onready var computer_list: Array = get_tree().get_nodes_in_group("computers")
@onready var robotmesh = get_node("MeshAndAnimation/RobotAnimated/Robot_Armature/Skeleton3D/RobotMesh")

@onready var item_hand = get_node("CanvasLayer/SubViewportContainer/SubViewport/Camera3D/PrimaryHand")

const WALK_SPEED : float = 3
const RUN_SPEED : float = 5
var pullback_time : float = 0.0
var max_pullback_time : float = 2.0

var can_interact : bool = true
var gamestate: PeerGameState
var inventory_index: int = 0
@export var inventory_size: int = 6
@onready var inventory: Array[Item]
@onready var max_inventory_slots = inventory_size
@onready var inventory_node: Node = %hud.get_node("Hotbar/HBoxContainer")

func _ready() -> void:
	for i in range(inventory_size):
		inventory.append(null)
	gamestate = PeerGameState.new()
	set_hotbar_index(0)
	camera.fov = Settings.fov
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	load_skin()

func load_skin() -> void:
	for computer in computer_list:
		if computer is SkinPicker:
			computer.set_player_head(self, gamestate.head_type)
			for body_part in gamestate.colors:
				var color = gamestate.colors[body_part]
				set_bodypart_color(color, body_part)

func interact() -> void:
	Debug.debug("you can not interact now")
	can_interact = false
	var timer = Timer.new()
	timer.connect("timeout", _on_interact_timeout.bind(timer))
	timer.start(0.25)


func pickup_item(item: Item) -> void:
	item.position = Vector3.ZERO
	item.rotation = Vector3.ZERO
	item.thing_holding_me = self
	#item.get_node("CollisionShape3D").disabled = true
	item.get_parent().remove_child(item)
	item.get_picked_up()
	Debug.debug("Attempting to pick up item")
	# if the player has an item, fill in next slot
	if held_item != null:
		for i in range(len(inventory)):
			if inventory[i] == null:
				inventory[i] = item
				var new_slot = inventory_node.get_child(i)
				new_slot.texture = item.inventory_texture
				new_slot.stretch_mode = TextureRect.StretchMode.STRETCH_SCALE
				Debug.debug("Picking up item in inventory")
				break
	else:
		inventory[inventory_index] = item
		var new_slot = inventory_node.get_child(inventory_index)
		new_slot.texture = item.inventory_texture
		new_slot.stretch_mode = TextureRect.StretchMode.STRETCH_SCALE
		Debug.debug("Picking up item in hand")
	update_held_item()

func update_held_item() -> void:
	var item: Item = inventory[inventory_index]
	held_item = item
	for child in item_hand.get_children():
		item_hand.remove_child(child)
	if item != null:
		item_hand.add_child(held_item)

func get_looking_at_ray():
	dropray.force_raycast_update()
	if dropray.is_colliding():
		return (dropray.get_collision_point())
	else:
		return null


func drop_item() -> void:
	Debug.debug("dropping item")
	# remove item from hotbar
	# remove item from players hand
	# remove item from inventory
	# drop item on ground
	# if youre holding an item
	if held_item != null:
		# set item to null
		inventory[inventory_index] = null
		# remove image from hotbar
		inventory_node.get_child(inventory_index - 1).texture = null
		held_item.thing_holding_me = null
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
			downray.rotation.x = -gameplay_head.get_node("HeadPivot").rotation.x
			downray.force_raycast_update()
			if downray.is_colliding():
				droppoint = downray.get_collision_point()
			else:
				held_item.queue_free()
		if held_item:
			held_item.position = droppoint
			var world = get_tree().get_first_node_in_group("world")
			world.get_node("Items").add_child(held_item)
			held_item.rotation = Vector3(0, rotation.y, 0)

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

func set_bodypart_color(color, body_part_selected) -> void:
	Debug.debug(body_part_selected)
	if body_part_selected == Global.PlayerBodyPart.EYES:
		Debug.debug("Chanigng eyue color")
		robot_eye_material.set_shader_parameter("emission_color", color)
	else:
		robot_armor_shader.set_shader_parameter("color_" + str(body_part_selected), color)

func _physics_process(delta: float) -> void:
	if held_item != null and increment_progress_bar:
		var diff = 100.0/held_item.hold_duration * delta
		$hud/TextureProgressBar.value += diff

	if not is_on_floor():
		velocity += get_gravity() * delta
	 
	if held_item != null:
		if ItemUsableComponent in held_item.item_components:
			if held_item.held_down_item: # if its an item you must hold down to use
				if Input.is_action_just_released("lmb"):
					held_item.stop_using_item()
				if Input.is_action_just_pressed("lmb"):
					held_item.begin_using_item()
			else: # if its an item you click to use
				if Input.is_action_just_pressed("lmb"):
					held_item.use_item()
			if Input.is_action_just_pressed("reload"):
				held_item.reload_item()
		if Input.is_action_just_pressed("drop"):
			drop_item()
		if ItemSnappableComponent in held_item.item_components:
			pass
	
	if Input.is_action_just_pressed("scroll_down"):
		set_hotbar_index((inventory_index + 1) % max_inventory_slots)
	elif Input.is_action_just_pressed("scroll_up"):
		set_hotbar_index((inventory_index - 1) % max_inventory_slots)
	elif Input.is_action_just_pressed("one"):
		set_hotbar_index(0)
	elif Input.is_action_just_pressed("two"):
		set_hotbar_index(1)
	elif Input.is_action_just_pressed("three"):
		set_hotbar_index(2)
	elif Input.is_action_just_pressed("four"):
		set_hotbar_index(3)
	elif Input.is_action_just_pressed("five"):
		set_hotbar_index(4)
	elif Input.is_action_just_pressed("six"):
		set_hotbar_index(5)
	elif Input.is_action_just_pressed("seven"):
		set_hotbar_index(6)
	elif Input.is_action_just_pressed("eight"):
		set_hotbar_index(7)
	elif Input.is_action_just_pressed("nine"):
		set_hotbar_index(8)
	elif Input.is_action_just_pressed("zero"):
		set_hotbar_index(9)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_just_pressed("pause"):
		pause_menu.toggle_pause_menu()
	var input_dir := Input.get_vector("left", "right", "forward", "backwards")
	if held_item != null:
		if ItemUsableComponent in held_item.item_components:
			var item_usable_component: ItemUsableComponent = held_item.get_node("ItemUsableComponent")
			if item_usable_component.can_move_while_using and item_usable_component.using_item:
				input_dir = Vector2.ZERO
	var direction: Vector3 = (gameplay_head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if input_dir.x != 0:
		# Interpolate rotation to the target angle
		camera.rotation.z = lerp(camera.rotation.z, round(input_dir.x) * deg_to_rad(-1.5), .2)
	else:
		# Interpolate back to the neutral position (0 rotation)
		camera.rotation.z = lerp(camera.rotation.z, 0.0, 0.2)
	var movement_speed = WALK_SPEED
	if Input.is_action_pressed("run") and input_dir.y < 0:
		movement_speed = RUN_SPEED
		camera.fov = lerp(camera.fov, float(Settings.fov + 10), 0.2)
	else:
		camera.fov = lerp(camera.fov, float(Settings.fov), 0.2)
	var local_velocity = get_node("MeshAndAnimation").basis.inverse() * velocity
	get_node("MeshAndAnimation/AnimationTree")["parameters/WalkVector/blend_position"] = -Vector2(local_velocity.x, local_velocity.z)
	#get_node("MeshAndAnimation/AnimationTree")["parameters/LookAngle/blend_position"] = Vector2(gameplay_head.rotation.y, gameplay_head.get_node("HeadPivot").rotation.x)

	if input_dir != Vector2.ZERO and is_on_floor():
		camera.v_offset = lerp(camera.v_offset, sin(Time.get_unix_time_from_system()*3 * movement_speed)/48 * movement_speed, 0.2)
	else:
		camera.v_offset = lerp(camera.v_offset, 0.0, 0.2)
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * movement_speed, ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, direction.z * movement_speed, ACCELERATION * delta)
		# if walking forward
		if local_velocity.z < 0:
			var target_rotation = gameplay_head.global_transform.basis.get_euler().y  # Get head's global Y rotation
			var current_rotation = $MeshAndAnimation.global_transform.basis.get_euler().y  # Get body's global Y rotation

			# Smoothly interpolate the body's rotation toward the head's direction
			var new_body_rotation = lerp_angle(current_rotation, target_rotation, .02)
			$MeshAndAnimation.rotation.y = new_body_rotation
			
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		velocity.z = move_toward(velocity.z, 0, FRICTION * delta)
		rotational_offset = 0
	move_and_slide()

func normalize_angle(degrees: float) -> float:
	if degrees < 0:
		return fmod(degrees - 180, 360) + 180
	elif degrees > 0:
		return fmod(degrees + 180, 360) - 180
	else:
		return 0


func handle_computers(event: InputEvent) -> void:
	if pause_menu.pause_menu_opened:
		return
	computerray.force_raycast_update()
	for computer: Node3D in computer_list:
		if computerray.is_colliding():
			var viewport = computer.get_node("SubViewport")
			var raycast_result = computerray.get_collision_point()
			var mesh_instance = computer.get_node("MeshInstance3D")
			
			var quad_size = mesh_instance.mesh.size
			var viewport_size = viewport.size
			
			var local_point = computer.to_local(raycast_result)
			var uv_x = (local_point.x / quad_size.x) + 0.5
			var uv_y = 1 - ((local_point.y / quad_size.y) + 0.5)
			
			var actual_coords = Vector2(uv_x * viewport_size.x, uv_y * viewport_size.y)

			# Forward the event to the computer node
			if event is InputEventMouseMotion or event is InputEventMouseButton or event is InputEventKey:
				computer.input(event, actual_coords)
		else:
			computer.mouse_outside_area()

func _process(_delta: float) -> void:
	# check to see if youre hovering over an interactable using the interactray
	interactray.check_interactions(self)
	var event = InputEventMouseMotion.new()
	handle_computers(event)


func _input(event):
	if event is InputEvent:
		handle_computers(event) # this is for handling viewports
	if held_item != null:
		if ItemUsableComponent in held_item.item_components:
			var item_usable_component: ItemUsableComponent = held_item.get_node("ItemUsableComponent")
			if not item_usable_component.can_move_while_using and item_usable_component.using_item:
				return  # Prevent movement if conditions are met

	var mesh_node = get_node("MeshAndAnimation")
	var animation_tree = mesh_node.get_node("AnimationTree")

	var body_rotation = rad_to_deg(mesh_node.rotation.y)
	var local_head_y_rotation = wrap(rad_to_deg(gameplay_head.rotation.y), 0, 360)
	var y_head_rotation = normalize_angle(local_head_y_rotation - body_rotation)

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var input = -event.relative * deg_to_rad(mouse_sensitivity)
	
		# Head rotation
		gameplay_head.rotate_y(input.x)
		head_pivot.rotate_x(input.y)

		# Clamp vertical head rotation
		head_pivot.rotation.x = clampf(head_pivot.rotation.x, deg_to_rad(-90), deg_to_rad(90))

	# Clamp head turn angle
	y_head_rotation = clamp(y_head_rotation, -MAX_HEAD_TURN_ANGLE, MAX_HEAD_TURN_ANGLE)
	# Update animation blend position
	animation_tree["parameters/LookAngle/blend_position"] = Vector2(
		-y_head_rotation,  
		rad_to_deg(head_pivot.rotation.x)
	)

	# Smoothly update body rotation
	mesh_node.rotation.y = deg_to_rad(local_head_y_rotation - y_head_rotation) - rotational_offset
		
func _on_interact_timeout(timer) -> void:
	Debug.debug("you can interact now")
	can_interact = true
	timer.queue_free()
