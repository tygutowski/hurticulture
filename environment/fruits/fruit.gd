class_name Fruit
extends Holdable

@export var fuel_amount : float = 10000
@export var is_on_tree: bool = false

func _ready():
	freeze = is_on_tree

func pick() -> void:
	is_on_tree = false
	freeze = false

func holding() -> void:
	if is_on_tree:
		pick()
