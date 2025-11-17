extends Node
class_name ObjectGenerator

var spawn_ray: RayCast3D

@onready var map_generator: MapGenerator = get_parent()

func _ready() -> void:
	spawn_ray = RayCast3D.new()
	spawn_ray.target_position = Vector3(0, -1000, 0)
	spawn_ray.enabled = true
	add_child(spawn_ray)

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

		var biome: Biome = chunk.get_biome_at_world_pos(wx, wy, chunk, map_generator.chunk_size)

		var world_point: Vector3 = spawn_ray.get_collision_point()
		var prob = randf()
		match biome.id:
			Global.biomeEnum.CARBON_WASTES:
				if prob <= 0.01:
					spawn("res://environment/biomes/carbon_wastes/ribcage_ridge.tscn", chunk, world_point)
			Global.biomeEnum.SKYLOOM_MEADOW:
				if prob <= 0.3:
					continue
				elif prob <= 0.7:
					# mini floater
					pass
				else:
					# big floater
					pass

func spawn(scene, chunk, position) -> void:
	var object = load(scene).instantiate()
	chunk.add_child(object)
	object.global_position = position
