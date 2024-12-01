@tool

extends Node
class_name MapGenerator

@export_category("Debug")
@export var debugging: bool = false:
	set(value):
		if value == debugging : return
		debugging = value
		notify_property_list_changed()

@export var generate: bool = false:
	set(value):
		if value == generate : return
		generate = value
		if generate == true:
			generate_in_editor()
		notify_property_list_changed()

@export var generation_override: bool = false:
	set(value):
		if value == generation_override : return
		generation_override = value
		notify_property_list_changed()

@export var clear: bool = false:
	set(value):
		if value == clear : return
		clear = value
		clear_world()
		notify_property_list_changed()

@export var random: bool = true:
	set(value):
		if value == random : return
		random = value
		notify_property_list_changed()

var currently_generating: bool = false
var custom_seed: int = 122001

@export_category("Terrain Generation")

var map_size: int = 100

var resolution_multiplier: float = 2.0
var might_crash: bool = false

@export_category("Heightmap Generation")
var heightmap: Array = []
var heightmap_texture: ImageTexture

@export_category("Biome Map Generation")
var biomemap_noise: FastNoiseLite

var biome_list: Array[Biome] = []
var humidity_noise: FastNoiseLite
var temperature_noise: FastNoiseLite
var heightmap_as_texture: ImageTexture
@onready var ray: RayCast3D = $RayCast3D

func get_vertex_count() -> int:
	return ((map_size + 1) * resolution_multiplier) ** 2

func _get_property_list():
	if Engine.is_editor_hint():
		var properties = []
		if debugging:
			properties.append({
				"name": "heightmap_as_texture",
				"type": TYPE_OBJECT,
				"hint": PROPERTY_HINT_RESOURCE_TYPE,
				"hint_string": "ImageTexture",
				"usage": PROPERTY_USAGE_DEFAULT
			})
			properties.append({
				"name": "map_size",
				"type": TYPE_FLOAT,
				"usage": PROPERTY_USAGE_DEFAULT,
				"hint": PROPERTY_HINT_RANGE,
				"hint_string" : "10,500,10"
			})
			properties.append({
				"name": "biomemap_blur",
				"type": TYPE_INT,
				"usage": PROPERTY_USAGE_DEFAULT,
				"hint": PROPERTY_HINT_RANGE,
				"hint_string" : "0,8,1"
			})
			properties.append({
				"name": "resolution_multiplier",
				"type": TYPE_FLOAT,
				"usage": PROPERTY_USAGE_DEFAULT,
				"hint": PROPERTY_HINT_RANGE,
				"hint_string" : "1,3.0,0.5"
			})
			properties.append({
				"name": "biomemap_noise",
				"type": TYPE_OBJECT,
				"hint": PROPERTY_HINT_RESOURCE_TYPE,
				"hint_string": "FastNoiseLite",
				"usage": PROPERTY_USAGE_DEFAULT
			})
			properties.append({
				"name": "biomemap_texture",
				"type": TYPE_OBJECT,
				"hint": PROPERTY_HINT_RESOURCE_TYPE,
				"hint_string": "ImageTexture",
				"usage": PROPERTY_USAGE_DEFAULT
			})
			properties.append({
				"name": "humidity_noise",
				"type": TYPE_OBJECT,
				"hint": PROPERTY_HINT_RESOURCE_TYPE,
				"hint_string": "FastNoiseLite",
				"usage": PROPERTY_USAGE_DEFAULT
			})
			properties.append({
				"name": "temperature_noise",
				"type": TYPE_OBJECT,
				"hint": PROPERTY_HINT_RESOURCE_TYPE,
				"hint_string": "FastNoiseLite",
				"usage": PROPERTY_USAGE_DEFAULT
			})
			properties.append({
				"name": "biome_list",
				"type": TYPE_ARRAY,
				"hint": PROPERTY_HINT_TYPE_STRING,
				"hint_string": "%d/%d:%s" % [TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, "Biome"],
				"usage": PROPERTY_USAGE_DEFAULT
			})
		return properties

@onready var tree_scenes = [
	preload("res://birch_002.tscn"),
	preload("res://birch_003.tscn")
]

@onready var bush_scenes = [
	preload("res://grass_01.tscn"),
	preload("res://grass_02.tscn"),
	preload("res://grass_03.tscn"),
	preload("res://grass_04.tscn"),
	preload("res://grass_05.tscn"),
	preload("res://grass_06.tscn"),
	preload("res://grass_07.tscn"),
	preload("res://grass_08.tscn"),
	preload("res://grass_09.tscn")
]

func clear_world() -> void:
	clear_mesh()
	clear_collision_shape()
	clear_objects()
	clear = false

func clear_mesh() -> void:
	$MeshInstance3D.mesh = null

func clear_collision_shape() -> void:
	for child in $StaticBody3D.get_children():
		child.queue_free()

func clear_objects() -> void:
	for spawned_object_categories in $GeneratedItems.get_children():
		for object in spawned_object_categories.get_children():
			object.queue_free()

func generate_in_editor() -> void:
	var number_of_vertices = get_vertex_count()
	if number_of_vertices > 100000:
		print("Too many vertices (%d), this might crash!" % number_of_vertices)
		if generation_override:
			print("Generation override enabled. Proceeding.")
		else:
			print("Enable generation override to proceed.")
			reset_generation_values()
			return
	print("Generating in the editor")
	set_seeds()
	clear_world()
	generate_terrain()
	reset_generation_values()

func set_seeds() -> void:
	if random:
		randomize()
	else:
		seed(custom_seed)
	for biome in biome_list:
		biome.heightmap.seed = randi()
	biomemap_noise.seed = randi()

func reset_generation_values() -> void:
	generate = false
	generation_override = false

func generate_world() -> void:
	$CameraArm/Camera3D.look_at(Vector3.ZERO)

	generate_terrain()
	await get_tree().physics_frame

	if not debugging:
		generate_vegetation()
		$CameraArm.queue_free()
		spawn_object("res://player/player.tscn", Vector2(0, 0), 3)
		spawn_object("res://environment/warehouse.tscn", Vector2(0, 0))
	else:
		get_parent().get_node("AnimationPlayer").seek(45)

func spawn_object(packed_scene: String, position: Vector2, height_offset: int = 0) -> void:
	ray.position = Vector3(position.x, 100, position.y)
	ray.target_position = Vector3(0, -300, 0)
	ray.force_raycast_update()
	if ray.is_colliding():
		var object_scene: PackedScene = load(packed_scene)
		var object = object_scene.instantiate()
		object.position = ray.get_collision_point() + Vector3(0, height_offset, 0)
		print("Spawning " + str(packed_scene) + " at " + str(object.position))
		get_node("GeneratedItems").add_child(object)
	else:
		print("Could not spawn " + str(packed_scene))

func generate_vegetation() -> void:
	generate_objects(tree_scenes, 4, 1000, 25, 150, "GeneratedItems/Trees")
	generate_objects(bush_scenes, 0, 20000, 0, 99999, "GeneratedItems/Bushes")

func generate_objects(object_scenes: Array, count: int, max_attempts: int, min_distance: float, max_distance: float, parent_path: String) -> void:
	var attempts = 0
	while count > 0 and attempts < max_attempts:
		attempts += 1
		ray.position = Vector3(randf_range(-map_size / 2, map_size / 2), 100, randf_range(-map_size / 2, map_size / 2))
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

func normalize_biome_heightmaps() -> void:
	for biome: Biome in biome_list:
		biome.normalize_heightmap(map_size)

func prepare_biome_weightmaps(biomemap) -> void:
	for biome: Biome in biome_list:
		biome.prepare_biome_weightmap(map_size, biomemap)

func convert_noise_to_image(noise: FastNoiseLite) -> Image:
	var image: Image = Image.create_empty(map_size, map_size, false, Image.FORMAT_L8)
	for x in range(map_size):
		for y in range(map_size):
			var pixel = noise.get_noise_2d(y, x)
			image.set_pixel(y, x, pixel)
	return image

func convert_image_to_texture(image: Image) -> ImageTexture:
	var texture = ImageTexture.create_from_image(image)
	return texture

func convert_noise_to_array(noise: FastNoiseLite) -> Array:
	var map = []
	for x in range(map_size):
		var row = []
		for y in range(map_size):
			var pixel = noise.get_noise_2d(y, x)
			pixel = (pixel + 1) / 2
			row.append(pixel)
		map.append(row)
	return map

func blend_biome_weights() -> void:
	for biome: Biome in biome_list:
		biome.blend_weights(map_size)

func prepare_biome_weights() -> Array:
	# Sum up all weights
	var total_weight: float = 0
	for biome: Biome in biome_list:
		total_weight += biome.weight
	
	# Check weight compared to others
	var weights: Array = []
	weights.append(0)
	for i: int in range(len(biome_list)):
		var biome: Biome = biome_list[i]
		var weight: float = biome.weight
		var comparative_weight: float = weight/total_weight
		weights.append(comparative_weight)
	
	var noise_weights = weights
	for i: int in range(1, len(weights)):
		var noise_weight = weights[i] + weights[i - 1]
		noise_weights[i] = noise_weight
	return noise_weights

func split_biomes_by_weight(biomemap: Array, biome_weights: Array) -> Array:
	var split_biomemap = []

	# Initialize each layer map for the biome ID ranges
	for i in range(len(biome_weights) - 1):
		var layer_map: Array = []
		for y in range(len(biomemap) + 1):
			var row = []
			for x in range(len(biomemap) + 1):
				row.append(0)
			layer_map.append(row)
		split_biomemap.append(layer_map)

	# Assign biome IDs based on weight ranges
	for y in range(map_size):
		for x in range(map_size):
			var value = biomemap[y][x]
			var counter = 0
			for i in range(len(biome_weights) - 1):
				if biome_weights[i] <= value and value < biome_weights[i + 1]:
					split_biomemap[i][y][x] = 1
					break
	return split_biomemap

func distribute_weights_to_biomes(biomemap_split: Array) -> void:
	for i: int in range(len(biome_list)):
		var biome: Biome = biome_list[i]
		var biomemap: Array = biomemap_split[i]
		biome.weightmap = biomemap_split[i]

func set_biome_ids() -> void:
	for i: int in range(len(biome_list)):
		var biome: Biome = biome_list[i]
		biome.biome_id = i

func generate_terrain() -> void:
	# Generate the heightmap for each biome
	normalize_biome_heightmaps()
	var biomemap = convert_noise_to_array(biomemap_noise)
	# Set the ID of each biome
	set_biome_ids()
	# Prepare a array of each biome's weights
	var biome_weights: Array = prepare_biome_weights()
	# Use the cellular biome map to split each cell into a biome
	var biomemap_split = split_biomes_by_weight(biomemap, biome_weights)
	# Split the weightmap for each biome
	distribute_weights_to_biomes(biomemap_split)
	# Blend the biome map for each biome
	# Each noise should be summed to 1.0
	blend_biome_weights()
	# Take each weight and noise, then create a heightmap
	heightmap = generate_heightmap()
	# Create terrain and collisionshape
	create_terrain_mesh()
	create_collision_shape()

func sum_array(array):
	var sum = 0.0
	for element in array:
		sum += element
	return sum

func generate_heightmap() -> Array:
	print("Generating heightmap")
	var map: Array = []
	for y in range(map_size):
		var row: Array = []
		for x in range(map_size):
			var value: float = 0
			for i in range(len(biome_list)):
				var biome: Biome = biome_list[i]
				var weightmap = biome.weightmap
				var noise: float = biome.heightmap.get_noise_2d(x, y)
				var weight = weightmap[x][y]
				var intensity = biome.intensity
				value += noise * weight * intensity
			row.append(value)
		map.append(row)
	return map

func create_terrain_mesh() -> void:
	print("Generating mesh")
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step = 1.0 / float(resolution_multiplier)
	var total_map_size = (map_size) * resolution_multiplier

	for x in range(total_map_size - 1):
		for y in range(total_map_size - 1):
			# Fetch heights at the four corners of the grid cell
			var h1 = heightmap[x    ][y    ]
			var h2 = heightmap[x + 1][y    ]
			var h3 = heightmap[x    ][y + 1]
			var h4 = heightmap[x + 1][y + 1]

			# Calculate vertex positions
			var p1 = Vector3(-map_size / 2 + y * step, h1, -map_size / 2 + x * step)
			var p2 = Vector3(-map_size / 2 + y * step, h2, -map_size / 2 + (x + 1) * step)
			var p3 = Vector3(-map_size / 2 + (y + 1) * step, h3, -map_size / 2 + x * step)
			var p4 = Vector3(-map_size / 2 + (y + 1) * step, h4, -map_size / 2 + (x + 1) * step)

			# Add vertices for the first triangle
			st.add_vertex(p1)
			st.add_vertex(p3)
			st.add_vertex(p2)
			
			# Add vertices for the second triangle
			st.add_vertex(p2)
			st.add_vertex(p3)
			st.add_vertex(p4)

	# Generate normals to ensure correct shading
	st.generate_normals()
	var generated_mesh = st.commit()
	$MeshInstance3D.mesh = generated_mesh

func create_collision_shape() -> void:
	print("Generating collision shape")
	var collision_shape = ConcavePolygonShape3D.new()
	var vertices: Array[Vector3] = []
	var step = 1.0 / float(resolution_multiplier)
	var total_map_size = map_size * resolution_multiplier

	for x in range(total_map_size - 1):
		for y in range(total_map_size - 1):
			var h1 = heightmap[x    ][y    ]
			var h2 = heightmap[x + 1][y    ]
			var h3 = heightmap[x    ][y + 1]
			var h4 = heightmap[x + 1][y + 1]

			var p1 = Vector3(-map_size / 2 +  y      * step, h1, -map_size / 2 +  x      * step)
			var p2 = Vector3(-map_size / 2 +  y      * step, h2, -map_size / 2 + (x + 1) * step)
			var p3 = Vector3(-map_size / 2 + (y + 1) * step, h3, -map_size / 2 +  x      * step)
			var p4 = Vector3(-map_size / 2 + (y + 1) * step, h4, -map_size / 2 + (x + 1) * step)

			vertices.append_array([p1, p3, p2, p2, p3, p4])

	collision_shape.set_faces(vertices)
	var collision_shape_instance = CollisionShape3D.new()
	collision_shape_instance.shape = collision_shape
	$StaticBody3D.add_child(collision_shape_instance)
