extends Node3D
class_name Item

@export var slot_texture: CompressedTexture2D = null
@export var held_down_item: bool = false
@export var hold_duration: float = 1.0
@export var use_interval: float = 0.5
@export var can_move_while_using: bool = true
@onready var player = get_tree().get_first_node_in_group("player")
var use_duration: float = 0.0
var interval_duration: float = 0.0
var thing_holding_me: Node = null
var using_item: bool = false

func _process(delta) -> void:
	if held_down_item and using_item:
		use_duration += delta
		interval_duration += delta
		if use_duration > hold_duration:
			finish_using_item()
		elif interval_duration / use_interval > 1.0:
			interval_duration -= use_interval
			update_interval()

func stop_player_chargebar() -> void:
	player.get_node("hud/TextureProgressBar").visible = false

func start_player_chargebar() -> void:
	player.get_node("hud/TextureProgressBar").visible = true
	player.get_node("hud/TextureProgressBar").value = 0
	player.increment_progress_bar = true

func begin_using_item() -> void:
	Debug.debug("Begin using item")
	using_item = true
	use_duration = 0
	interval_duration = 0
	start_player_chargebar()
	begin_being_used()

func use_item() -> void:
	be_used()

# Things that occur on an interval.
# e.g. while drilling a wall, particles will fly out every 0.5 seconds
func update_interval() -> void:
	Debug.debug("Continued using item")

func stop_using_item() -> void:
	if using_item:
		Debug.debug("Stop using item")
		using_item = false
		stop_player_chargebar()
		stop_being_used()

func finish_using_item() -> void:
	if using_item:
		Debug.debug("Finish using item")
		using_item = false
		stop_player_chargebar()
		finish_being_used()
		use_item()

func get_picked_up() -> void:
	get_node("Mesh").material_override.no_depth_test = true
	var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
	if animation_player != null:
		animation_player.play("pickup")
	for child in get_children():
		if child is CollisionShape3D:
			Debug.debug("disabling hitbox")
			child.disabled = true

func get_dropped() -> void:
	var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
	if animation_player != null:
		animation_player.stop()
	get_node("Mesh").material_override.no_depth_test = false
	for child in get_children():
		Debug.debug("child!")
		if child is CollisionShape3D:
			Debug.debug("enabling hitbox")
			child.disabled = false
	thing_holding_me = null

func get_picked_up_by(new_owner: Node) -> void:
	thing_holding_me = new_owner
	get_picked_up()

func reload_item() -> void:
	pass

func alt_use_item() -> void:
	pass

func be_used() -> void:
	pass

func finish_being_used() -> void:
	pass

func stop_being_used() -> void:
	pass

func begin_being_used() -> void:
	pass
