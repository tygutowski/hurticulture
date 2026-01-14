extends Node3D
class_name ObjectGenerator

@onready var map_generator: MapGenerator = get_parent()
@export var object_raycast: RayCast3D

const MIN_TREE_DIST: float = 3.0
const MAX_HEIGHT_DIFF: float = 1 # meters

func spawn_objects(chunk: Chunk) -> void:
	var biome: Biome = chunk.get_biome_at_world_pos(
		chunk.coords.x * map_generator.chunk_size + 0.5,
		chunk.coords.y * map_generator.chunk_size + 0.5,
		chunk,
		map_generator.chunk_size,
		map_generator.subchunks_per_chunk
	)

	match biome.id:
		Global.biomeEnum.CARBON_WASTES:
			spawn_biome_objects(
				Global.biomeEnum.CARBON_WASTES,
				load("res://environment/biomes/carbon_wastes/BurntStump.tscn"
				),
				chunk,
				0.10
			)
			spawn_biome_objects(
				Global.biomeEnum.CARBON_WASTES,
				load("res://environment/biomes/carbon_wastes/RibcageRidge.tscn"),
				chunk,
				0.001
			)
		Global.biomeEnum.SKYLOOM_MEADOW:
			spawn_biome_objects(
				Global.biomeEnum.SKYLOOM_MEADOW,
				load("res://environment/biomes/skyloom_meadows/PineTree.tscn"),
				chunk,
				0.000
			)
			spawn_biome_objects(
				Global.biomeEnum.SKYLOOM_MEADOW,
				load("res://environment/biomes/skyloom_meadows/ShortBush.tscn"),
				chunk,
				0.01,
				1.0,
				2.0
			)


func spawn_biome_objects(
	biome_id: int,
	scene: PackedScene,
	chunk: Chunk,
	probability: float,
	scale_min: float = 1.0,
	scale_max: float = 1.0
) -> void:

	var sub_len: float = map_generator.subchunk_length
	var base_x: float = chunk.coords.x * map_generator.chunk_size
	var base_y: float = chunk.coords.y * map_generator.chunk_size

	for sx: int in range(map_generator.subchunks_per_chunk):
		for sy: int in range(map_generator.subchunks_per_chunk):

			var wx: float = base_x + sx * sub_len + randf_range(0.0, sub_len)
			var wy: float = base_y + sy * sub_len + randf_range(0.0, sub_len)

			# sample biome at this point
			var biome_here: Biome = chunk.get_biome_at_world_pos(
				wx,
				wy,
				chunk,
				map_generator.chunk_size,
				map_generator.subchunks_per_chunk
			)

			if biome_here.id != biome_id:
				continue

			# raycast to ground
			object_raycast.global_position = Vector3(wx, 1000.0, wy)
			object_raycast.force_raycast_update()
			if not object_raycast.is_colliding():
				continue

			# roll
			if randf() > probability:
				continue

			var hit: Vector3 = object_raycast.get_collision_point()
			var rot: float = randf_range(0.0, TAU)
			var scl: float = randf_range(scale_min, scale_max)

			spawn(scene, chunk, hit, rot, scl)


func spawn(scene: PackedScene, chunk: Chunk, position: Vector3, rotation: float = 0, scale: float = 1) -> void:
	var object = scene.instantiate()
	chunk.add_child(object)
	object.scale = Vector3(scale, scale, scale)
	object.global_position = position
	object.rotate_y(rotation)

func _is_flat_enough(normal: Vector3, max_slope_deg: float = 10.0) -> bool:
	var min_dot: float = cos(deg_to_rad(max_slope_deg))
	return normal.dot(Vector3.UP) >= min_dot
