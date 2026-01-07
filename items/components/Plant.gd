extends Node3D
class_name Plant

@export var time_to_grow: int = 60
var final_grow_duration: float = 0.0

@export var visual_animation: AnimationPlayer
@export var collision_animation: AnimationPlayer
@export var growth_label: Label3D

@export var fruit_spawns: Array[Node3D]
var empty_fruit_spawns: Array[Node3D]
@export_file_path("*.tscn") var fruit_path_to_spawn
@onready var fruit_to_spawn = load(fruit_path_to_spawn)

var can_grow_fruit: bool = false

@export_range(0.0, 1.0) var growth: float = 0.0:
	set(value):
		growth = clamp(value, 0.0, 1.0)
		if growth_label != null:
			growth_label.text = str(int(growth * 100)) + "%"
		if not Engine.is_editor_hint():
			return

		_seek_growth(visual_animation)
		_seek_growth(collision_animation)

func _seek_growth(player: AnimationPlayer) -> void:
	if player == null:
		return
	if not player.has_animation("Grow"):
		return

	var anim: Animation = player.get_animation("Grow")
	var t: float = anim.length * growth

	if player.current_animation != "Grow":
		player.play("Grow")

	player.seek(t, true)
	player.pause()

func _ready() -> void:
	if final_grow_duration <= 0.0:
		final_grow_duration = randf_range(
			time_to_grow * 0.8,
			time_to_grow * 1.2
		)
	empty_fruit_spawns = fruit_spawns.duplicate(true)
	_setup_animation_player(visual_animation)
	_setup_animation_player(collision_animation)

func _setup_animation_player(player: AnimationPlayer) -> void:
	if player == null or not player.has_animation("Grow"):
		return

	var anim: Animation = player.get_animation("Grow")
	player.speed_scale = anim.length / final_grow_duration

	player.play("Grow")
	player.seek(anim.length * growth, true)

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	growth = visual_animation.current_animation_position / visual_animation.get_animation("Grow").length
	
	if growth >= 1 and not empty_fruit_spawns.is_empty():
		var spawn_chance = randi_range(1,160)
		if spawn_chance == 1:
			spawn_fruit()

func spawn_fruit() -> void:
	if empty_fruit_spawns.is_empty():
		return
	var fruit_spawn = empty_fruit_spawns.pick_random()
	var fruit: Fruit = fruit_to_spawn.instantiate()
	fruit.rotate_y(randf_range(0, 2*PI))
	fruit.freeze = true
	fruit.on_plant = true
	empty_fruit_spawns.erase(fruit_spawn)
	fruit_spawn.add_child(fruit)
	fruit.owner = self

func get_fruit_picked(fruit_spawn) -> void:
	empty_fruit_spawns.append(fruit_spawn)
