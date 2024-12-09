extends Item
class_name Seed

var seed_type = ''

# Seed is used to instance Plants
func plant_seed() -> void:
	var plant_scene: PackedScene = load("res://environment/plants/plant_" + str(seed_type) + ".tscn")
	var plant: Plant = plant_scene.instantiate()
