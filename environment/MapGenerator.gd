extends Node
class_name MapGenerator

signal generation_finished

@export_category("Terrain Generation")
var chunk_size: int = 12
var generate_radius: int = 12
var unload_radius: int = 12

var directions: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
@export var chunks: Dictionary[Vector2, Chunk] = {}

@onready var chunk_scene: PackedScene = load("res://world_generation/Chunk.tscn")
@onready var terrain_generator: TerrainGenerator = get_node("TerrainGenerator")
@onready var biome_generator: BiomeGenerator = get_node("BiomeGenerator")
@onready var player: Player = get_node("../player")

var last_chunk: Vector2 = Vector2.INF

func _ready() -> void:
	biome_generator.initialize()
	Debug.setup_debug()

func _process(_delta) -> void:
	if player == null:
		return
	var current_chunk: Vector2 = get_player_coordinates()

	if current_chunk != last_chunk and not player.freeze_map:
		update_visible_chunks()
		last_chunk = current_chunk

func get_player_coordinates() -> Vector2:
	return Vector2(
		floor(player.global_position.x/chunk_size),
		floor(player.global_position.z/chunk_size)
	)

func get_needed_coords(center: Vector2) -> Array[Vector2]:
	var arr: Array[Vector2] = []
	for x in range(-generate_radius, generate_radius + 1):
		for y in range(-generate_radius, generate_radius + 1):
			arr.append(center + Vector2(x, y))
	return arr

func update_visible_chunks() -> void:
	var player_coords := get_player_coordinates()
	var player_pos = Vector2(player.global_position.x, player.global_position.z)
	var temperature = terrain_generator.temperature_map.get_noise_2dv(player_pos)
	Debug.debug("pos: " + str(player_pos))
	Debug.debug("chunk: " + str(player_coords))
	var humidity = terrain_generator.humidity_map.get_noise_2dv(player_pos)
	Debug.debug("temp: " + str((temperature + 1) / 2))
	Debug.debug("humid: " + str((humidity + 1) / 2))
	var biome: Biome = biome_generator.get_biome_at(0, temperature, humidity, 0)
	Debug.debug("biome: " + biome.biome_name)
	var needed := get_needed_coords(player_coords)

	# Load only new ones
	for coords in needed:
		if not chunks.has(coords):
			create_chunk(coords)
	# Unload
	for coords in chunks.keys():
		if coords not in needed:
			unload_chunk(coords)

func unload_chunk(coords: Vector2) -> void:
	var chunk := chunks[coords]
	if is_instance_valid(chunk):
		chunk.queue_free()
	chunks.erase(coords)


func create_chunk(coords: Vector2) -> void:
	var chunk: Chunk = chunk_scene.instantiate()
	get_node("Chunks").add_child(chunk)

	chunk.coords = coords
	chunk.name = "Chunk %s,%s" % [coords.x, coords.y]
	chunk.global_position = Vector3(coords.x * chunk_size, 0, coords.y * chunk_size)

	chunks[coords] = chunk

	update_chunk_mesh(chunk)
	update_collider(chunk)
	terrain_generator.generate_chunk_data(chunk)
	chunk.flat_array = make_flat_texture_array(biome_generator.biome_list)
	apply_biome_data_to_chunk(chunk, chunk_size, biome_generator.biome_list, chunk.flat_array)
	
func make_flat_texture_array(biomes: Array[Biome]) -> Texture2DArray:
	var images: Array[Image] = []

	for biome: Biome in biomes:
		var img: Image = biome.flat_texture.get_image()
		
		if img.get_format() != Image.FORMAT_RGBA8:
			img.convert(Image.FORMAT_RGBA8)

		images.append(img)

	var arr: Texture2DArray = Texture2DArray.new()
	arr.create_from_images(images)
	return arr


func apply_biome_data_to_chunk(chunk: Chunk, chunk_size: int, biome_list: Array[Biome], flat_array: Texture2DArray) -> void:
	var index_texture: Texture2D = make_biome_index_texture(chunk, chunk_size, biome_list)

	var mesh_instance: MeshInstance3D = chunk.get_node("MeshInstance3D")
	var mat: ShaderMaterial = mesh_instance.material_override
	var mat_inst: ShaderMaterial = mat.duplicate() as ShaderMaterial
	
	mat_inst.set_shader_parameter("biome_index_map", index_texture)
	mat_inst.set_shader_parameter("flat_textures", flat_array)
	mat_inst.set_shader_parameter("biome_count", biome_list.size())
	
	mesh_instance.material_override = mat_inst

# this sends chunk info to the shader to designate which biome each subchunk is 
func make_biome_index_texture(chunk: Chunk, chunk_size: int, biome_list: Array[Biome]) -> ImageTexture:
	var img: Image = Image.create(chunk_size, chunk_size, false, Image.FORMAT_RF)
	for x in range(chunk_size):
		for y in range(chunk_size):
			var biome: Biome = chunk.biome_map[x][y]
			var idx: int = biome_list.find(biome)
			img.set_pixel(x, y, Color(float(idx), 0.0, 0.0))	
	return ImageTexture.create_from_image(img)

func get_chunk(coords: Vector2) -> Chunk:
	if chunks.has(coords):
		return chunks[coords]

	var chunk: Chunk = chunk_scene.instantiate()
	chunk.coords = coords
	chunk.name = "Chunk %s,%s" % [coords.x, coords.y]
	chunk.is_new = true

	chunks[coords] = chunk
	get_node("Chunks").add_child(chunk)

	return chunk

func delete_old_chunks() -> void:
	var player_coords: Vector2 = get_player_coordinates()
	var to_remove: Array[Vector2] = []

	for key: Vector2 in chunks.keys():
		var c: Chunk = chunks[key]
		var d := c.coords - player_coords

		var dist := int(max(abs(d.x), abs(d.y)))
		if dist > unload_radius:
			to_remove.append(key)

	for key: Vector2 in to_remove:
		if is_instance_valid(chunks[key]):
			chunks[key].queue_free()
		chunks.erase(key)


func update_chunk_mesh(chunk: Chunk) -> void:
	var mesh := generate_chunk_mesh(chunk.coords)
	chunk.get_node("MeshInstance3D").mesh = mesh


func update_collider(chunk: Chunk) -> void:
	var collider := generate_chunk_collision_shape(chunk.coords)
	chunk.get_node("StaticBody3D/CollisionShape3D").shape = collider

func generate_chunk_mesh(coords: Vector2) -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var pos: Vector2 = coords * chunk_size

	for y in range(0, chunk_size):
		for x in range(0, chunk_size):
			var h1 := terrain_generator.get_height(pos + Vector2(x, y))
			var h2 := terrain_generator.get_height(pos + Vector2(x + 1, y))
			var h3 := terrain_generator.get_height(pos + Vector2(x, y + 1))
			var h4 := terrain_generator.get_height(pos + Vector2(x + 1, y + 1))

			var p1 := Vector3(x, h1, y)
			var p2 := Vector3(x + 1, h2, y)
			var p3 := Vector3(x, h3, y + 1)
			var p4 := Vector3(x + 1, h4, y + 1)

			var uv1 := Vector2(x / float(chunk_size), y / float(chunk_size))
			var uv2 := Vector2((x + 1) / float(chunk_size), y / float(chunk_size))
			var uv3 := Vector2(x / float(chunk_size), (y + 1) / float(chunk_size))
			var uv4 := Vector2((x + 1) / float(chunk_size), (y + 1) / float(chunk_size))

			st.set_uv(uv1); st.add_vertex(p1)
			st.set_uv(uv2); st.add_vertex(p2)
			st.set_uv(uv3); st.add_vertex(p3)

			st.set_uv(uv2); st.add_vertex(p2)
			st.set_uv(uv4); st.add_vertex(p4)
			st.set_uv(uv3); st.add_vertex(p3)

	st.generate_normals()
	return st.commit()


func generate_chunk_collision_shape(coords: Vector2) -> ConcavePolygonShape3D:
	var faces := PackedVector3Array()
	var pos: Vector2 = coords * chunk_size

	for y in range(0, chunk_size):
		for x in range(0, chunk_size):
			var h1 := terrain_generator.get_height(pos + Vector2(x, y))
			var h2 := terrain_generator.get_height(pos + Vector2(x + 1, y))
			var h3 := terrain_generator.get_height(pos + Vector2(x, y + 1))
			var h4 := terrain_generator.get_height(pos + Vector2(x + 1, y + 1))

			var p1 := Vector3(x, h1, y)
			var p2 := Vector3(x + 1, h2, y)
			var p3 := Vector3(x, h3, y + 1)
			var p4 := Vector3(x + 1, h4, y + 1)

			faces.append_array([p1, p2, p3])
			faces.append_array([p2, p4, p3])

	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	return shape
