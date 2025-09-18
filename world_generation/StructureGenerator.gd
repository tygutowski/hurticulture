extends Node
class_name StructureGenerator

var map_generator: MapGenerator

func _init(parent: MapGenerator) -> void:
	map_generator = parent

func force_spawn_object(packed_scene: String, position: Vector3, path: String = "GeneratedItems"):
	var object_scene: PackedScene = load(packed_scene)
	var object = object_scene.instantiate()
	object.position = position
	get_node(path).add_child(object)

func spawn_object(packed_scene: String, position: Vector3):
	ray.position = Vector3(position.x, 100, position.y)
	ray.target_position = Vector3(0, -300, 0)
	ray.force_raycast_update()
	if ray.is_colliding():
		var object_scene: PackedScene = load(packed_scene)
		var object = object_scene.instantiate()
		object.position = ray.get_collision_point()
		get_node("GeneratedItems").add_child(object)
		return object

func generate_objects(object_scenes: Array, count: int, max_attempts: int, min_distance: float, max_distance: float, parent_path: String) -> void:
	var attempts = 0
	var half_map = float(map_size) / 2
	while count > 0 and attempts < max_attempts:
		attempts += 1
		ray.position = Vector3(randf_range(-half_map, half_map), 100, randf_range(-half_map, half_map))
		ray.target_position = Vector3(0, -1000, 0)
		ray.force_raycast_update()

		if not (min_distance < ray.position.length() and ray.position.length() < max_distance):
			continue

		if ray.is_colliding():
			var object = object_scenes.pick_random().instantiate()
			object.position = ray.get_collision_point()
			object.scale = Vector3(randf_range(0.9, 1.1), randf_range(0.8, 1.2), randf_range(0.9, 1.1))
			object.rotation.y = randf_range(0, 2 * PI)
			get_node(parent_path).add_child(object)
			count -= 1

func spawn_warehouse():
	var height_threshold: float = 0.5
	var height_threshold_delta: float = 0.1
	var warehouse_scene: PackedScene = load("res://environment/Warehouse.tscn")
	var warehouse: Node3D = warehouse_scene.instantiate()
	get_node("GeneratedItems").add_child(warehouse)
	var edges: Array[Node] = warehouse.get_node("GroundedAreas").get_children()
	var attempts: int = 0
	var max_attempts: int = 200
	var found_area: bool = false
	# increase the tolerance the longer we search
	while found_area == false:
		while attempts < max_attempts:
			attempts += 1
			var x_pos = randf_range(-(map_size / 2.0) + 5, (map_size / 2.0) - 5)
			var z_pos = randf_range(-(map_size / 2.0) + 5, (map_size / 2.0) - 5)
			var base_position = Vector3(x_pos, 100, z_pos)
			var base_hit = cast_ray(base_position)

			if base_hit == null:
				continue  # No ground detected, retry

			warehouse.position = base_hit
			

			var height_samples: Array = []
			var valid_terrain: bool = true

			# Check height consistency over a 5x5 grid around edges
			for edge in edges:
				var edge_pos = warehouse.to_global(edge.position)
				for i in range(5):
					for j in range(5):
						var offset = Vector3((i - 2) * 2, 0, (j - 2) * 2)  # Grid sampling
						var sample_pos = edge_pos + offset + Vector3(0, 100, 0)
						var sample_hit = cast_ray(sample_pos)
						if sample_hit == Vector3.INF:
							valid_terrain = false
							break
						height_samples.append(sample_hit.y)
						print(abs(sample_hit.y - base_hit.y))
						if abs(sample_hit.y - base_hit.y) > height_threshold:
							valid_terrain = false
							break
					if not valid_terrain:
						break
				if not valid_terrain:
					break

			# Ensure no edge is too far apart
			if valid_terrain:
				var min_height = height_samples.min()
				var max_height = height_samples.max()
				if (max_height - min_height) <= height_threshold:
					return warehouse
		height_threshold += height_threshold_delta
		attempts = 0
