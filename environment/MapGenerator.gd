extends Node
class_name MapGenerator

signal generation_finished

@export_category("Terrain Generation")
@export_range(16, 64, 16) var chunk_size: int = 16
@onready var max_lod: int = int(floor(log(chunk_size / 16) / log(2)))
@export_range(1, 64, 1, "chunks") var generate_radius: int = 5
@export_range(1, 64, 1, "chunks") var unload_radius: int = 5

var chunks: Dictionary[Vector2, Chunk] = {}

@onready var chunk_scene: PackedScene = load("res://world_generation/Chunk.tscn")
@onready var terrain_generator: TerrainGenerator = get_node("TerrainGenerator")
@onready var player: Player = get_node("../player")
var last_chunk: Vector2 = Vector2.INF
var generation_thread: Thread

func _ready() -> void:
	generation_thread = Thread.new()
	generation_finished.connect(Debug.setup_debug)
	update_visible_chunks()

func _process(_delta) -> void:
	if player == null:
		return
	var current_chunk: Vector2 = get_chunk_coordinate()

	if current_chunk != last_chunk:
		update_visible_chunks()
		last_chunk = current_chunk

func get_chunk_coordinate() -> Vector2:
	return Vector2(
		floor(player.global_position.x/chunk_size),
		floor(player.global_position.z/chunk_size)
	)

func update_visible_chunks(reset_everything: bool = false) -> void:
	delete_old_chunks(reset_everything)
	
	var coords: Vector2 = get_chunk_coordinate()
	for x in range(-generate_radius, generate_radius + 1):
		for y in range(-generate_radius, generate_radius + 1):
			var chunk_coord = Vector2(coords.x + x, coords.y + y)
			var lod = get_lod(Vector2(x, y))
			var chunk: Chunk = get_chunk(chunk_coord, lod)
			chunk.global_position = Vector3(chunk_coord.x * chunk_size, 0, chunk_coord.y * chunk_size)
			update_mesh(chunk)

func update_mesh(chunk: Chunk) -> void:
	var target_lod: int = get_lod(Vector2(chunk.coords))
	if chunk.lod != target_lod:
		chunk.lod = target_lod
		var new_mesh: Mesh = generate_chunk_mesh(chunk.coords, target_lod)
		chunk.get_node("MeshInstance3D").mesh = new_mesh
		chunk.global_position = Vector3(chunk.coords.x * chunk_size, 0, chunk.coords.y * chunk_size)

func update_collider(chunk: Chunk) -> void:
	var new_collider: ConcavePolygonShape3D = generate_chunk_collision_shape(chunk.coords, 1)
	chunk.get_node("StaticBody3D/CollisionShape3D").shape = new_collider

func get_lod(coords: Vector2) -> int:
	var r: int = int(max(abs(coords.x), abs(coords.y)))
	if r <= 1:
		return 0
	elif r <= 3:
		return 1
	elif r == 4:
		return 3
	else:
		return 4

func get_chunk(coords: Vector2, lod: int) -> Chunk:
	if chunks.has(coords):
		return chunks[coords]
	var chunk = chunk_scene.instantiate()
	chunk.coords = coords
	chunks[coords] = chunk
	get_node("Chunks").add_child(chunk)
	return chunk

func delete_old_chunks(reset_everything: bool = false) -> void:
	var coords: Vector2 = get_chunk_coordinate()
	var to_remove: Array = []

	for chunk_coord in chunks.keys():
		if reset_everything:
			to_remove.append(chunk_coord)
			continue
		var offset: Vector2 = chunk_coord - coords
		var dist: int = int(max(abs(offset.x), abs(offset.y))) # Chebyshev distance

		if dist > unload_radius:
			to_remove.append(chunk_coord)


	for coord in to_remove:
		var chunk: Chunk = chunks[coord]
		chunk.queue_free()
		chunks.erase(coord)


func generate_chunk_mesh(coords: Vector2, lod: int) -> Mesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var lod_step: int = pow(2, lod)
	var pos: Vector2 = coords * chunk_size
	
	for y in range(0, chunk_size, lod_step):
		for x in range(0, chunk_size, lod_step):
			
			var h1: float = terrain_generator.get_height(pos + Vector2(x, y))
			var h2: float = terrain_generator.get_height(pos + Vector2(x + lod_step, y))
			var h3: float = terrain_generator.get_height(pos + Vector2(x, y + lod_step))
			var h4: float = terrain_generator.get_height(pos + Vector2(x + lod_step, y + lod_step))

			var p1: Vector3 = Vector3(x, h1, y)
			var p2: Vector3 = Vector3(x + lod_step, h2, y)
			var p3: Vector3 = Vector3(x, h3, y + lod_step)
			var p4: Vector3 = Vector3(x + lod_step, h4, y + lod_step)

			var uv1: Vector2 = Vector2(float(x)     / chunk_size, float(y)     / chunk_size)
			var uv2: Vector2 = Vector2(float(x + lod_step) / chunk_size, float(y)     / chunk_size)
			var uv3: Vector2 = Vector2(float(x)     / chunk_size, float(y + lod_step) / chunk_size)
			var uv4: Vector2 = Vector2(float(x + lod_step) / chunk_size, float(y + lod_step) / chunk_size)
			
			st.set_smooth_group(1)
			# First tri
			st.set_uv(uv1);
			st.add_vertex(p1)
			st.set_uv(uv2);
			st.add_vertex(p2)
			st.set_uv(uv3);
			st.add_vertex(p3)


			# Second tri
			st.set_uv(uv2);
			st.add_vertex(p2)
			st.set_uv(uv4);
			st.add_vertex(p4)
			st.set_uv(uv3);
			st.add_vertex(p3)


	#TODO: Blend the normals, there are artifacts along the chunk borders
	st.generate_normals()
	return st.commit()

func generate_chunk_collision_shape(coords: Vector2, lod: int) -> ConcavePolygonShape3D:
	var faces: PackedVector3Array = PackedVector3Array()

	var lod_step: int = pow(2, lod)
	var pos: Vector2 = coords * chunk_size
	
	for y in range(0, chunk_size, lod_step):
		for x in range(0, chunk_size, lod_step):
			var h1: float = terrain_generator.get_height(pos + Vector2(x, y))
			var h2: float = terrain_generator.get_height(pos + Vector2(x + lod_step, y))
			var h3: float = terrain_generator.get_height(pos + Vector2(x, y + lod_step))
			var h4: float = terrain_generator.get_height(pos + Vector2(x + lod_step, y + lod_step))

			var p1: Vector3 = Vector3(x, h1, y)
			var p2: Vector3 = Vector3(x + lod_step, h2, y)
			var p3: Vector3 = Vector3(x, h3, y + lod_step)
			var p4: Vector3 = Vector3(x + lod_step, h4, y + lod_step)

			# First tri
			faces.append_array([p1, p2, p3])
			# Second tri
			faces.append_array([p2, p4, p3])

	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	return shape
