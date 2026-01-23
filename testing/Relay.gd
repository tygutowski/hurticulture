extends Item

var is_deployed: bool = false

func _on_picked_up() -> void:
	
	freeze = false
	is_deployed = false

func deployed() -> void:
	
	freeze = true
	is_deployed = true
