class_name Player
extends CharacterBody3D

var mouse_sensitivity = 0.3
const JUMP_VELOCITY = 5
const ACCELERATION : float = 13
const FRICTION : float = 20
const MAX_HEAD_TURN_ANGLE: float = 25
var increment_progress_bar: bool = false
var item_preventing_movement: bool = false
var rotational_offset: float = 0
var charging_drop: bool = false
var drop_charge_time: float = 0

@export var robot_eye_material: ShaderMaterial = null
@export var robot_armor_shader: ShaderMaterial = null

@onready var head = get_node("Head")
@onready var animation_head = head.get_node("BoneAttachment3D/HeadAnimation")
@onready var gameplay_head = head.get_node("HeadGameplay")
@onready var head_pivot: Node3D = gameplay_head.get_node("HeadPivot")
@onready var dropray: RayCast3D = head_pivot.get_node("Dropray")
@onready var interactray: RayCast3D = head_pivot.get_node("InteractRay")
@onready var computerray: RayCast3D = head_pivot.get_node("ComputerRay")
var held_item: Item = null
var feet_stance_angle: float = 0
@onready var camera = gameplay_head.get_node("HeadPivot/Camera3D")
@onready var pause_menu = get_node("PauseMenu")

@onready var computer_list: Array = get_tree().get_nodes_in_group("computers")
@onready var robotmesh = get_node("MeshAndAnimation/RobotAnimated/Robot_Armature/Skeleton3D/RobotMesh")
@export var holding_bones: Array[LookAtModifier3D] = []

const WALK_SPEED : float = 5
const RUN_SPEED : float = 8
var pullback_time : float = 0.0
var max_pullback_time : float = 2.0

var can_interact : bool = true
var gamestate: PeerGameState
var inventory_index: int = 0
@export_range(0,10,1) var inventory_size: int = 6
@onready var inventory: Array[Item]
@onready var max_inventory_slots = inventory_size
@onready var inventory_node: Node = %hud.get_node("Hotbar/HBoxContainer")
@onready var fps_hand = get_node("CanvasLayer/SubViewportContainer/SubViewport/Camera3D/Hand")
@onready var world_hand: Node3D = get_node("BoneAttachment3D/ItemHand")

@export_category("Debug")
@export var noclip: bool = false
@export var freeze_map: bool = false
@export var debug_info: bool = false

func _ready() -> void:
	Settings.settings_initialized.connect(load_settings)
	for i in range(inventory_size):
		inventory.append(null)
	gamestate = PeerGameState.new()
	set_inventory_index(0)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	load_skin()

func load_settings() -> void:
	camera.fov = Settings.fov

# adds the item to your first person hand
func add_item_to_fps_hand(item: Node3D) -> void:
	Debug.debug("adding to fps")
	var fps_hand_item = item.duplicate(15)
	var meshes: Array = fps_hand_item.find_children("*", "MeshInstance3D", true, true)
	item.set_counterpart(fps_hand_item)
	for mesh: MeshInstance3D in meshes:
		# make it only visible to the fps hand camera
		mesh.set_layer_mask_value(1, false)
		mesh.set_layer_mask_value(3, false)
		mesh.set_layer_mask_value(4, true)
	fps_hand.add_child(fps_hand_item)
	fps_hand_item.viewport_type = fps_hand_item.viewportType.FIRSTPERSON
	fps_hand_item.orient_item()

# adds the item to your real world hand
func add_item_to_world_hand(item: Node3D) -> void:
	Debug.debug("adding to world")
	var meshes: Array = item.find_children("*", "MeshInstance3D", true, true)
	for mesh: MeshInstance3D in meshes:
		# make it only visible to the fps hand camera
		mesh.set_layer_mask_value(1, false)
		mesh.set_layer_mask_value(3, true)
		mesh.set_layer_mask_value(4, false)
	world_hand.add_child(item)
	item.viewport_type = item.viewportType.REALWORLD
	item.orient_item()

# removes the item from your first person hand
func remove_item_from_fps_hand() -> void:
	Debug.debug("removing from fps")
	for child in fps_hand.get_children():
		child.queue_free()

# removes the item from the real world hand
func remove_item_from_world_hand() -> void:
	Debug.debug("removing from world")
	for child in world_hand.get_children():
		var meshes: Array = child.find_children("*", "MeshInstance3D", true, true)
		for mesh: MeshInstance3D in meshes:
			# make it only visible to the fps hand camera
			mesh.set_layer_mask_value(1, true)
			mesh.set_layer_mask_value(3, true)
			mesh.set_layer_mask_value(4, false)
		world_hand.remove_child(child)

func load_skin() -> void:
	for computer in computer_list:
		if computer is SkinPicker:
			computer.set_player_head(self, gamestate.head_type)
			for body_part in gamestate.colors:
				var color = gamestate.colors[body_part]
				set_bodypart_color(color, body_part)

# interact with something
func interact() -> void:
	Debug.debug("you can not interact now")
	can_interact = false
	var timer = Timer.new()
	timer.connect("timeout", _on_interact_timeout.bind(timer))
	timer.start(0.25)

# pick up and item and put it in your inventory
func pickup_item(item: Item) -> void:
	item.set_item_components()
	item.get_parent().remove_child(item)
	item.get_picked_up_by(self)

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

# update the item, this is called whenever your inventory is updated
# (changing hotbar slot, picking up items, dropping items)
func update_held_item() -> void:
	held_item = inventory[inventory_index]
	remove_item_from_world_hand()
	remove_item_from_fps_hand()
	if held_item != null:
		add_item_to_fps_hand(held_item)
		add_item_to_world_hand(held_item)
		for bone in holding_bones:
			bone.active = true
	else:
		for bone in holding_bones:
			bone.active = false

func get_looking_at_ray():
	dropray.force_raycast_update()
	if dropray.is_colliding():
		return (dropray.get_collision_point())
	else:
		return null

# removes the item from your inventory
# updates held_item
# update your hand to show that its free
func drop_item(drop_charge: float = 0) -> void:
	charging_drop = false
	drop_charge = clamp(drop_charge, 0.0, 5.0)
	Debug.debug("dropping item")
	if held_item != null:
		remove_item_from_world_hand()
		held_item.get_dropped()
		inventory[inventory_index] = null
		inventory_node.get_child(inventory_index).texture = null

		# Drop position: right at the gameplay head (e.g., eyes)
		held_item.position = gameplay_head.global_transform.origin
		held_item.rotation = Vector3(0, gameplay_head.rotation.y, 0)

		# Add to world before applying physics
		var world = get_tree().get_first_node_in_group("world")
		world.get_node("Items").add_child(held_item)

		await get_tree().physics_frame  # Ensure physics system knows about it

		held_item.sleeping = false

		# Use forward vector from gameplay head (supports up/down)
		var forward = -head_pivot.global_transform.basis.z.normalized()
		var impulse_strength = clamp(5.0 * drop_charge, 1.5, 8.0)
		var impulse = forward.normalized() * impulse_strength
		
		var inherited_velocity = velocity
		held_item.linear_velocity = inherited_velocity
		# This puts a little spin on the item in the air
		held_item.apply_impulse(
			Vector3(0, 0, randf_range(-0.01, 0.01)),
			Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
			)
		held_item.apply_central_impulse(impulse)
		update_held_item()




func set_inventory_index(index: int) -> void:
	if inventory_size == 0:
		return
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

func begin_charging_drop() -> void:
	charging_drop = true
	drop_charge_time = 0

func update_head_rotation() -> void:
	# prevent the head from rotating too far up or down
	head_pivot.rotation.x = clampf(head_pivot.rotation.x, deg_to_rad(-90), deg_to_rad(90))



func _physics_process(delta: float) -> void:
	if charging_drop:
		drop_charge_time = min(drop_charge_time + delta, 3.0)
	else:
		drop_charge_time = 0
	camera.fov = lerp(camera.fov, Settings.base_fov + drop_charge_time * 3, .75)
	
	if not is_on_floor():
		if not noclip:
			velocity += get_gravity() * delta
	 
	if held_item != null:
		for component in held_item.item_components:
			if component is ItemUsableComponent:
				if component.held_down_item: # if its an item you must hold down to use
					if Input.is_action_just_released("lmb"):
						held_item.get_node("ItemUsableComponent").stop_using_item()
					if Input.is_action_just_pressed("lmb"):
						held_item.get_node("ItemUsableComponent").begin_using_item()
				else: # if its an item you click to use
					if Input.is_action_just_pressed("lmb"):
						held_item.use_item()
				if Input.is_action_just_pressed("reload"):
					held_item.reload_item()
			if component is ItemSnappableComponent:
				pass
		
		
		if Input.is_action_just_pressed("drop"):
			begin_charging_drop()
		if Input.is_action_just_released("drop"):
			drop_item(drop_charge_time)
	if max_inventory_slots > 0:
		if Input.is_action_just_pressed("scroll_down"):
			set_inventory_index((inventory_index + 1) % max_inventory_slots)
		elif Input.is_action_just_pressed("scroll_up"):
			set_inventory_index((inventory_index - 1) % max_inventory_slots)
		elif Input.is_action_just_pressed("one"):
			set_inventory_index(0)
		elif Input.is_action_just_pressed("two"):
			set_inventory_index(1)
		elif Input.is_action_just_pressed("three"):
			set_inventory_index(2)
		elif Input.is_action_just_pressed("four"):
			set_inventory_index(3)
		elif Input.is_action_just_pressed("five"):
			set_inventory_index(4)
		elif Input.is_action_just_pressed("six"):
			set_inventory_index(5)
		elif Input.is_action_just_pressed("seven"):
			set_inventory_index(6)
		elif Input.is_action_just_pressed("eight"):
			set_inventory_index(7)
		elif Input.is_action_just_pressed("nine"):
			set_inventory_index(8)
		elif Input.is_action_just_pressed("zero"):
			set_inventory_index(9)
	
	if Input.is_action_just_pressed("fly"):
		noclip = not noclip
	if Input.is_action_just_pressed("freeze_map"):
		freeze_map = not freeze_map
	
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
		camera.v_offset = lerp(camera.v_offset, sin(Time.get_unix_time_from_system()*2 * movement_speed)/48 * movement_speed, 0.2)
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
	
	if noclip:
		var combined_basis: Basis = gameplay_head.global_transform.basis * head_pivot.transform.basis
		direction = (combined_basis.z * input_dir.y + combined_basis.x * input_dir.x).normalized()
		velocity = direction * 20
		if Input.is_action_pressed("run"):
			velocity = direction * 150
		if Input.is_action_pressed("crouch"):
			velocity.y += -20
		elif Input.is_action_pressed("jump"):
			velocity.y += 20
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
	handle_computer_cursor_movement()

func handle_computer_cursor_movement():
	var event = InputEventMouseMotion.new()
	handle_computers(event)

func handle_computer_cursor_input(event):
	if event is InputEvent:
		handle_computers(event) # this is for handling viewports

func _input(event):
	handle_computer_cursor_input(event)
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
	
		update_head_rotation()

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
