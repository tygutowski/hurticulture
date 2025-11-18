extends Node
class_name FloraGenerator

var grass_mesh: Mesh = preload("res://environment/biomes/skyloom_meadows/Squort.tres")
var spawn_ray: RayCast3D


var generation_thread: Thread
var generation_mutex: Mutex

@onready var map_generator: MapGenerator = get_parent()

func _ready() -> void:
	spawn_ray = RayCast3D.new()
	spawn_ray.target_position = Vector3(0, -1000, 0)
	spawn_ray.enabled = true
	add_child(spawn_ray)
	
func initialize(_generation_thread: Thread = null, _generation_mutex: Mutex = null) -> void:
	generation_thread = _generation_thread
	generation_mutex = _generation_mutex
	
func generate_grass(chunk: Chunk) -> void:
	var chunk_seed: int = hash(chunk.coords)
	seed(chunk_seed)
	var attempts: int = 50
	var max_instances: int = 50

	var grass_multimesh: MultiMesh = MultiMesh.new()
	grass_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	grass_multimesh.instance_count = max_instances
	grass_multimesh.mesh = grass_mesh

	var grass_multimesh_instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	grass_multimesh_instance.multimesh = grass_multimesh
	chunk.add_child(grass_multimesh_instance)

	var placed: int = 0
	var base_x: float = chunk.coords.x * map_generator.chunk_size
	var base_y: float = chunk.coords.y * map_generator.chunk_size

	for _i: int in range(attempts):
		if placed >= max_instances:
			break

		var wx: float = base_x + randf_range(0.0, map_generator.chunk_size)
		var wy: float = base_y + randf_range(0.0, map_generator.chunk_size)

		spawn_ray.global_position = Vector3(wx, 100.0, wy)
		spawn_ray.force_raycast_update()
		if not spawn_ray.is_colliding():
			continue

		var biome: Biome = chunk.get_biome_at_world_pos(wx, wy, chunk, map_generator.chunk_size, map_generator.subchunks_per_chunk)

		match biome.id:
			Global.biomeEnum.CARBON_WASTES:
				continue
			Global.biomeEnum.SKYLOOM_MEADOW:
				if randf() > 0.9:
					continue

		var world_point: Vector3 = spawn_ray.get_collision_point()
		var local_point: Vector3 = Vector3(
			world_point.x - base_x,
			world_point.y,
			world_point.z - base_y
		)

		var xf: Transform3D = Transform3D()
		xf.origin = local_point
		grass_multimesh.set_instance_transform(placed, xf)

		placed += 1
