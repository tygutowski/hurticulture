class_name Player
extends CharacterBody3D

var mouse_sensitivity = 0.3
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var is_holding : bool = false
var held_item : Node3D = null
@onready var head = get_node("Head")
@onready var pause_menu = get_node("pausemenu")
@onready var timer = get_node("Timer")

var pullback_time : float = 0.0
var max_pullback_time : float = 2.0

var can_interact : bool = true

func _ready() -> void:
	head.get_node("Camera3D").fov = Settings.fov
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func interact() -> void:
	print("you can not interact now")
	can_interact = false
	timer.start()

func pickup_item(item : Node3D) -> void:
	print("picking up item")
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

func _physics_process(delta: float) -> void:
	MultiplayerManager.send_p2p_packet(0, {
		"message"   : "player_update",
		"from"      : MultiplayerManager.get_steam_id(),
		"transform" : global_transform
	})
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
	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_just_pressed("pause"):
		pause_menu.toggle_pause_menu()
	
	var input_dir := Input.get_vector("left", "right", "forward", "backwards")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * deg_to_rad(mouse_sensitivity))
		head.rotate_x(-event.relative.y * deg_to_rad(mouse_sensitivity))
		head.rotation.x = clampf(head.rotation.x, -deg_to_rad(70), deg_to_rad(70))


func _on_timer_timeout() -> void:
	print("you can interact now")
	can_interact = true
