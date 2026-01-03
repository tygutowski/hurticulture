extends Item
class_name Fruit

var on_plant: bool = false

func get_picked() -> void:
	freeze = false
	var fruit_spawn = get_parent()
	get_parent().owner.get_fruit_picked(fruit_spawn)
	on_plant = false
