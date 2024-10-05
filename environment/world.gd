extends Node3D

@onready var player = get_node("player")

func _physics_process(_delta: float) -> void:
	get_tree().call_group("enemy", "update_target_location", player.global_transform.origin)

func _ready():
	PowerManager.game_started()
