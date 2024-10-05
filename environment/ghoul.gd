extends Node3D

@onready var player = get_tree().get_first_node_in_group("player")
@onready var sprite = get_node("Body")
@onready var ray = get_node("RayCast3D")
@onready var world = get_tree().get_first_node_in_group("world")
var disappearing : bool = false
@onready var timer = get_node("Timer")
var speed = 5
@export var run_dir : int = 0
var has_seen_player : bool = false
@export var run_distance = 10
var death_time = 0.15

func _ready():
	sprite.get_node("Hand").no_depth_test = false
	sprite.get_node("Hand/Fingers").no_depth_test = false
	sprite.get_node("Head").no_depth_test = false
	sprite.get_node("Head/Eyes").no_depth_test = false

func _process(_delta: float) -> void:
	var player_global = player.global_transform.origin
	sprite.look_at(player_global)
	ray.target_position = to_local(player_global)
	ray.force_raycast_update()
	
	var runaway_vector = player_global - global_position
	var collider = ray.get_collider()
	
	if not has_seen_player and collider == player:
		sprite.get_node("Hand").no_depth_test = true
		sprite.get_node("Hand/Fingers").no_depth_test = true
		sprite.get_node("Head").no_depth_test = true
		sprite.get_node("Head/Eyes").no_depth_test = true
		has_seen_player = true
	if has_seen_player:
		if disappearing:
			var perpendicular_vector = runaway_vector.normalized().cross(Vector3.UP).normalized()
			perpendicular_vector = Vector3(perpendicular_vector.x, 0, perpendicular_vector.z)
			var tween = get_tree().create_tween()
			tween.set_ease(Tween.EASE_IN)
			print(perpendicular_vector * run_dir)
			tween.tween_property(self, "global_position", global_position + perpendicular_vector * -10 * run_dir, death_time - .01)
		else:
			if collider != player or player_global.distance_to(global_position) <= run_distance:
				timer.start(death_time)
				disappearing = true
				sprite.get_node("Hand").no_depth_test = false
				sprite.get_node("Hand/Fingers").no_depth_test = false
				sprite.get_node("Head").no_depth_test = false
				sprite.get_node("Head/Eyes").no_depth_test = false
			
func _on_timer_timeout() -> void:
	queue_free()
