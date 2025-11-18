extends Node
class_name MapGenerator

@export_category("Terrain Generation")
var chunk_size: int = 16
var subchunks_per_chunk: int = 8
var generate_radius: int = 12
var unload_radius: int = 12
var subchunk_length: int = chunk_size / subchunks_per_chunk

# how many chunks to load each frame. this prevents
# massive lagspikes when loading new chunks
const CHUNKS_PER_FRAME: int = 1

var directions: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
@export var chunks: Dictionary[Vector2, Chunk] = {}

@onready var chunk_scene: PackedScene = load("res://world_generation/Chunk.tscn")
@onready var terrain_generator: TerrainGenerator = get_node("TerrainGenerator")
@onready var biome_generator: BiomeGenerator = get_node("BiomeGenerator")
@onready var flora_generator: FloraGenerator = get_node("FloraGenerator")
@onready var object_generator: ObjectGenerator = get_node("ObjectGenerator")
@onready var flat_array: Texture2DArray = make_flat_texture_array(biome_generator.biome_list)

@onready var chunks_node: Node = get_node("Chunks")

@onready var player: Player = get_node("../player")

var chunks_pending: Dictionary[Vector2, bool] = {}
var chunks_to_generate: Array[Vector2] = []
@export var using_threading: bool = true

var biome_update_timer: float = 0
var biome_update_timer_threshold: float = 0.5

var last_chunk: Vector2 = Vector2.INF

var generation_thread: Thread
var generation_mutex: Mutex

var needed_cache: Array[Vector2] = []
var needed_cache_center: Vector2 = Vector2.INF

var player_coords: Vector2 = Vector2.ZERO

func _ready() -> void:
	terrain_generator.initialize(generation_thread, generation_mutex)
	biome_generator.initialize(generation_thread, generation_mutex)
	flora_generator.initialize(generation_thread, generation_mutex)
	object_generator.initialize(generation_thread, generation_mutex)
	Debug.setup_debug()

func process_chunk_queue() -> void:
	var count: int = 0

	while chunks_to_generate.size() > 0 and count < CHUNKS_PER_FRAME:
		var coords: Vector2 = chunks_to_generate.pop_front()
		await create_chunk(coords, self)
		count += 1

func cleanup_stragglers() -> void:
	var needed: Array[Vector2] = get_needed_coords(player_coords)

	var to_remove: Array[Vector2] = []
	for coords: Vector2 in chunks.keys():
		# If chunk is not needed and not queued for generation, remove it
		if coords not in needed and coords not in chunks_to_generate:
			to_remove.append(coords)

	for coords: Vector2 in to_remove:
		var chunk: Chunk = chunks[coords]
		if is_instance_valid(chunk):
			chunk.queue_free()
		chunks.erase(coords)


func _process(delta) -> void:
	biome_update_timer += delta
	if biome_update_timer >= biome_update_timer_threshold:
		biome_update_timer -= biome_update_timer_threshold
		update_biome()
	if player == null:
		return
	update_player_coordinates()
	var current_chunk: Vector2 = player_coords
	process_chunk_queue()
	cleanup_stragglers()
	if current_chunk != last_chunk and not player.freeze_map:
		if using_threading:
			generation_thread = Thread.new()
			generation_thread.start(update_visible_chunks.bind(self))
		else:
			update_visible_chunks(self)

		last_chunk = current_chunk
	
func update_player_coordinates() -> void:
	player_coords = Vector2(
		floor(player.global_position.x/chunk_size),
		floor(player.global_position.z/chunk_size)
	)

func get_needed_coords(center: Vector2) -> Array[Vector2]:
	if center == needed_cache_center:
		return needed_cache

	needed_cache_center = center
	var arr: Array[Vector2] = []

	for x: int in range(-generate_radius, generate_radius + 1):
		for y: int in range(-generate_radius, generate_radius + 1):
			arr.append(center + Vector2(x, y))

	needed_cache = arr
	return arr

func update_biome() -> void:
	var player_pos = Vector2(player.global_position.x, player.global_position.z)
	var temperature = terrain_generator.temperature_map.get_noise_2dv(player_pos)
	Debug.debug("pos: " + str(player_pos))
	var humidity = terrain_generator.humidity_map.get_noise_2dv(player_pos)
	Debug.debug("temp: " + str((temperature + 1) / 2))
	Debug.debug("humid: " + str((humidity + 1) / 2))
	var biome: Biome = biome_generator.get_biome_at(0, temperature, humidity, 0)
	Debug.debug("biome: " + biome.biome_name)
	var env: Environment = get_node("../WorldEnvironment").environment
	
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(
		env,
		"fog_light_color",
		biome.fog_color,
		0.6
	)

func update_visible_chunks(map_generator: Node) -> void:
	var needed := get_needed_coords(player_coords)
	for coords in needed:
		if not chunks.has(coords) and not chunks_pending.has(coords):
			chunks_pending[coords] = true
			chunks_to_generate.append(coords)

	for coords in chunks.keys():
		if coords not in needed and coords not in chunks_pending:
			unload_chunk(coords)


func unload_chunk(coords: Vector2) -> void:
	var chunk := chunks[coords]
	if is_instance_valid(chunk):
		chunk.queue_free()
	chunks.erase(coords)

func create_chunk(coords, map_generator: Node) -> void:
	var chunk: Chunk = chunk_scene.instantiate()
	chunks_node.add_child(chunk)
	chunk.coords = coords
	chunk.name = "Chunk %s,%s" % [coords.x, coords.y]
	chunk.global_position = Vector3(coords.x * chunk_size, 0, coords.y * chunk_size)
	chunks[coords] = chunk
	#await chunk.chunk_ready

	generate_chunk_mesh_and_collider(chunk)

	terrain_generator.generate_chunk_data(chunk)
	await get_tree().physics_frame
	
	if !is_instance_valid(chunk):
		if chunks_pending.has(coords):
			chunks_pending.erase(coords)
		return

	chunk.flat_array = flat_array
	apply_biome_data_to_chunk(chunk, biome_generator.biome_list, flat_array)

	# Always clear pending
	if chunks_pending.has(coords):
		chunks_pending.erase(coords)

	# If finished too late → discard
	if coords not in get_needed_coords(player_coords):
		if is_instance_valid(chunk):
			chunk.queue_free()
		chunks.erase(coords)

	flora_generator.generate_grass(chunk)
	object_generator.spawn_objects(chunk)
	if chunk.coords == Vector2.ZERO:
		object_generator.spawn_structure(true, load("res://environment/biomes/carbon_wastes/escape_pod.tscn"), chunk)


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


func apply_biome_data_to_chunk(chunk: Chunk, biome_list: Array[Biome], flat_array: Texture2DArray) -> void:
	var index_texture: Texture2D = make_biome_index_texture(chunk, biome_list)

	var mat: ShaderMaterial = chunk.mesh_instance.material_override
	var mat_inst: ShaderMaterial = mat.duplicate() as ShaderMaterial
	
	mat_inst.set_shader_parameter("biome_index_map", index_texture)
	mat_inst.set_shader_parameter("flat_textures", flat_array)
	mat_inst.set_shader_parameter("biome_count", biome_list.size())
	
	chunk.mesh_instance.material_override = mat_inst

# this sends chunk info to the shader to designate which biome each subchunk is 
func make_biome_index_texture(chunk: Chunk, biome_list: Array[Biome]) -> ImageTexture:
	var img: Image = Image.create(subchunks_per_chunk, subchunks_per_chunk, false, Image.FORMAT_RF)
	for x in range(0, subchunks_per_chunk):
		for y in range(0, subchunks_per_chunk):
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
	update_player_coordinates()
	var current_chunk: Vector2 = player_coords
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

func generate_chunk_mesh_and_collider(chunk: Chunk) -> void:
	var st := SurfaceTool.new()
	var faces := PackedVector3Array()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var pos: Vector2 = chunk.coords * chunk_size
	for y in range(0, chunk_size, subchunk_length):
		for x in range(0, chunk_size, subchunk_length):
			var h1 := terrain_generator.get_height(pos + Vector2(x, y))
			var h2 := terrain_generator.get_height(pos + Vector2(x + subchunk_length, y))
			var h3 := terrain_generator.get_height(pos + Vector2(x, y + subchunk_length))
			var h4 := terrain_generator.get_height(pos + Vector2(x + subchunk_length, y + subchunk_length))

			var p1 := Vector3(x, h1, y)
			var p2 := Vector3(x + subchunk_length, h2, y)
			var p3 := Vector3(x, h3, y + subchunk_length)
			var p4 := Vector3(x + subchunk_length, h4, y + subchunk_length)

			var uv1 := Vector2(x / float(chunk_size), y / float(chunk_size))
			var uv2 := Vector2((x + subchunk_length) / float(chunk_size), y / float(chunk_size))
			var uv3 := Vector2(x / float(chunk_size), (y + subchunk_length) / float(chunk_size))
			var uv4 := Vector2((x + subchunk_length) / float(chunk_size), (y + subchunk_length) / float(chunk_size))

			st.set_uv(uv1); st.add_vertex(p1)
			st.set_uv(uv2); st.add_vertex(p2)
			st.set_uv(uv3); st.add_vertex(p3)

			st.set_uv(uv2); st.add_vertex(p2)
			st.set_uv(uv4); st.add_vertex(p4)
			st.set_uv(uv3); st.add_vertex(p3)
			faces.append_array([p1, p2, p3])
			faces.append_array([p2, p4, p3])
	st.generate_normals()
	chunk.get_node("MeshInstance3D").mesh = st.commit()
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	chunk.get_node("StaticBody3D/CollisionShape3D").shape = shape
	await get_tree().physics_frame
