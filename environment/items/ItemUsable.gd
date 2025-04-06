extends Node3D
class_name ItemUsableComponent

# Usable Items
@export var held_down_item: bool = false
@export var hold_duration: float = 1.0
@export var use_interval: float = 0.5
@export var can_move_while_using: bool = true
var using_item: bool = false
var interval_duration: float = 0.0
var use_duration: float = 0.0

func _ready() -> void:
	assert(get_parent() is Item)

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
	get_parent().thing_holding_me.get_node("hud/TextureProgressBar").visible = false

func start_player_chargebar() -> void:
	get_parent().thing_holding_me.get_node("hud/TextureProgressBar").visible = true
	get_parent().thing_holding_me.get_node("hud/TextureProgressBar").value = 0
	get_parent().thing_holding_me.increment_progress_bar = true

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
