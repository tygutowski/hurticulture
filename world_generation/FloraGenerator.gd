extends Node
class_name FloraGenerator

var map_generator: MapGenerator

func _init(parent: MapGenerator) -> void:
	map_generator = parent

func generate_vegetation() -> void:
	set_text("Planting trees")
	generate_trees(750)

func spawn_tree(pos: Vector2, tree: Node) -> void:
	print("spawning tree")
	get_node("GeneratedItems/Trees").add_child(tree)
	var position = Vector3(pos.x, 100, pos.y)
	ray.position = position
	tree.rotate_y(randf())
	ray.force_raycast_update()
	if not ray.is_colliding():
		return
	tree.position = ray.get_collision_point()

func generate_trees(number_of_trees: int) -> void:
	var half_map = float(map_size) / 2
	for tree in range(number_of_trees):
		var pos = Vector2(randf_range(-half_map, half_map), randf_range(-half_map, half_map))
		var int_pos = Vector2i(int(pos.x) + int(half_map), int(pos.y) + int(half_map))
		# random value between 0 and 1
		# to check which biome foliage it should generate for
		var value: float = .7#randf()
		for biome: Biome in biome_list:
			var weight = biome.weight_map[int_pos.x][int_pos.y]
			if weight >= value:
				spawn_tree(pos, biome.get_tree())
				break

func generate_grass(mesh_per_chunk: int, chunk_size: Vector2, map_size: Vector2) -> void:
	var grass_ray: RayCast3D = get_tree().get_first_node_in_group("world").get_node("WorldGenerator/RayCast3D2")
	var chunks_x: int = int(map_size.x / chunk_size.x)
	var chunks_y: int = int(map_size.y / chunk_size.y)
	var total_chunks: int = chunks_x * chunks_y

	for chunk in total_chunks:
		var multimesh_instance := MultiMeshInstance3D.new()
		var multimesh := MultiMesh.new()
		multimesh.mesh = load("res://vfx/grass/grass_lod2.tres")
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.instance_count = mesh_per_chunk
		multimesh.visible_instance_count = mesh_per_chunk

		var x_index: int = chunk % chunks_x
		var y_index: int = chunk / chunks_x
		multimesh_instance.name = "MultiMesh" + str(x_index) + ":" + str(y_index)
		var base_x_position: float = x_index * chunk_size.x - map_size.x / 2.0
		var base_y_position: float = y_index * chunk_size.y - map_size.y / 2.0

		for i in mesh_per_chunk:
			var random_position: Vector3 = Vector3(
				base_x_position + randf_range(0, chunk_size.x),
				500,
				base_y_position + randf_range(0, chunk_size.y)
			)

			grass_ray.global_position = random_position
			grass_ray.force_raycast_update()

			if grass_ray.is_colliding():
				var collision_point = grass_ray.get_collision_point()
				multimesh.set_instance_transform(i, Transform3D(Basis(), collision_point))

		multimesh_instance.multimesh = multimesh
		get_tree().get_first_node_in_group("world").add_child(multimesh_instance)
