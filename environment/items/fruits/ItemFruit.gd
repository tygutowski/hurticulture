extends Item

@export var fuel_amount : float = 10000
@export var is_on_tree: bool = false

func pick() -> void:
	is_on_tree = false

func holding() -> void:
	if is_on_tree:
		pick()
