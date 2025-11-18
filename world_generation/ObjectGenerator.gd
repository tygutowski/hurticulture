extends Node
class_name ObjectGenerator

var spawn_ray: RayCast3D

@onready var map_generator: MapGenerator = get_parent()

var generation_thread: Thread
var generation_mutex: Mutex

func _ready() -> void:
	spawn_ray = RayCast3D.new()
	spawn_ray.target_position = Vector3(0, -1000, 0)
	spawn_ray.enabled = true
	add_child(spawn_ray)

func initialize(_generation_thread: Thread = null, _generation_mutex: Mutex = null) -> void:
	generation_thread = _generation_thread
	generation_mutex = _generation_mutex
	
func spawn_objects(chunk: Chunk) -> void:
	var chunk_seed: int = hash(chunk.coords)
	seed(chunk_seed)
	var attempts: int = 1
	var base_x: float = chunk.coords.x * map_generator.chunk_size
	var base_y: float = chunk.coords.y * map_generator.chunk_size

	for _i: int in range(attempts):
		var wx: float = base_x + randf_range(0.0, map_generator.chunk_size)
		var wy: float = base_y + randf_range(0.0, map_generator.chunk_size)

		spawn_ray.global_position = Vector3(wx, 100.0, wy)
		spawn_ray.force_raycast_update()
		if not spawn_ray.is_colliding():
			continue

		var biome: Biome = chunk.get_biome_at_world_pos(wx, wy, chunk, map_generator.chunk_size, map_generator.subchunks_per_chunk)

		var world_point: Vector3 = spawn_ray.get_collision_point()
		var prob = randf()
		# chunk unique items
		match biome.id:
			Global.biomeEnum.CARBON_WASTES:
				if prob <= 0.01:
					spawn(load("res://environment/biomes/carbon_wastes/ribcage_ridge.tscn"), chunk, world_point, randf_range(0, 2*PI), randf_range(1.0, 2.0))
				if prob <= 0.1:
					spawn(load("res://environment/biomes/carbon_wastes/burnt_stump.tscn"), chunk, world_point, randf_range(0, 2*PI), randf_range(1.0, 2))
		match biome.id:
			Global.biomeEnum.SKYLOOM_MEADOW:
				for i in randi_range(5, 20):
					spawn(load("res://environment/biomes/skyloom_meadows/PineTree.tscn"), chunk, world_point, randf_range(0, 2*PI))

func spawn(scene: PackedScene, chunk: Chunk, position: Vector3, rotation: float = 0, scale: float = 1) -> void:
	var object = scene.instantiate()
	chunk.add_child(object)
	object.scale = Vector3(scale, scale, scale)
	object.global_position = position
	object.rotate_y(rotation)

func spawn_structure(must_spawn: bool, scene: PackedScene, chunk: Chunk, rotation: float = 0, scale: float = 1) -> void:
	var max_attempts: int = 100
	var attempt: int = 0
	while must_spawn or attempt < max_attempts:
		spawn_ray.global_position = Vector3(randf_range(0, 12), 100.0, randf_range(0,12))
		spawn_ray.force_raycast_update()
		var world_point: Vector3 = spawn_ray.get_collision_point()
		var normal: Vector3 = spawn_ray.get_collision_normal()
		if is_low_incline(normal):
			var object = scene.instantiate()
			chunk.add_child(object)
			object.scale = Vector3(scale, scale, scale)
			object.global_position = world_point
			object.rotate_y(rotation)
			return
		attempt += 1

func is_low_incline(normal: Vector3) -> bool:
	const MAX_ANGLE: float = deg_to_rad(20.0)
	var dot: float = clamp(normal.dot(Vector3.UP), -1.0, 1.0)
	var angle: float = acos(dot) # radians
	return angle <= MAX_ANGLE
