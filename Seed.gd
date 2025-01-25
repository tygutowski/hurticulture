extends Item
class_name Seed

enum SeedType {TEST}
var seed_type = SeedType.TEST

var seed_types: Dictionary = {
	SeedType.TEST: "test_plant"
}

# Seed is used to instance Plants
func plant_seed() -> void:
	var position_looking_at = thing_holding_me.get_looking_at_ray()
	if position_looking_at != null:
		var plant_scene: PackedScene = load("res://environment/plants/" + (seed_types[seed_type]) + ".tscn")
		var plant: Plant = plant_scene.instantiate()
		get_tree().get_first_node_in_group("world").get_node("Items").add_child(plant)
		plant.position = position_looking_at
		Debug.debug("Planting " + seed_types[seed_type])

func use_item() -> void:
	plant_seed()

func drop_item() -> void:
	pass

func reload_item() -> void:
	pass

func alt_use_item() -> void:
	pass
