extends Node
class_name MapGenerator

signal generation_finished

@export_category("Terrain Generation")
@export_range(16, 64, 16) var chunk_size: int = 16
@onready var max_lod: int = int(floor(log(chunk_size / 16) / log(2)))
@export_range(1, 64, 1, "chunks") var generate_radius: int = 5
@export_range(1, 64, 1, "chunks") var unload_radius: int = 5

var directions: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
@export var chunks: Dictionary[Vector2, Chunk] = {}

@onready var chunk_scene: PackedScene = load("res://world_generation/Chunk.tscn")
@onready var terrain_generator: TerrainGenerator = get_node("TerrainGenerator")
@onready var player: Player = get_node("../player")
var last_chunk: Vector2 = Vector2.INF
var generation_thread: Thread

func _ready() -> void:
	#get_viewport().debug_draw = Viewport.DEBUG_DRAW_OVERDRAW
	#get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME

	generation_thread = Thread.new()
	generation_finished.connect(Debug.setup_debug)
	update_visible_chunks()

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

func update_visible_chunks(reset_everything: bool = false) -> void:
	delete_old_chunks(true)
	
	# initialize chunks and LODs
	var player_coords: Vector2 = get_player_coordinates()
	for x in range(-generate_radius, generate_radius + 1):
		for y in range(-generate_radius, generate_radius + 1):
			var relative_chunk_coords = Vector2(player_coords.x + x, player_coords.y + y)
			var chunk: Chunk = get_chunk(relative_chunk_coords)
			chunk.lod = get_lod(Vector2(x, y))
			chunk.global_position = Vector3(relative_chunk_coords.x * chunk_size, 0, relative_chunk_coords.y * chunk_size)
	
	# update chunk data to account for seams
	for chunk_coord in chunks:
		var chunk: Chunk = chunks[chunk_coord]
		# this prepares all nearby chunks for their LODS
		chunk.directions_to_downscale = []
		
		# check each nearby chunk
		for direction in directions:
			var coords = chunk.coords + direction
			if chunks.has(coords):
				var adjacent_chunk = chunks.get(coords)
				if adjacent_chunk.lod > chunk.lod:
					chunk.directions_to_downscale.append(direction)
		
	# update mesh to account for LODs & seams
	for x in range(-generate_radius, generate_radius + 1):
		for y in range(-generate_radius, generate_radius + 1):
			var relative_chunk_coords = Vector2(player_coords.x + x, player_coords.y + y)
			var chunk: Chunk = get_chunk(relative_chunk_coords)
			assert(chunk.lod >= 0, "Chunk LOD hasn't been initialized")
			update_mesh(chunk, chunk.lod)
			chunk.get_node("Label3D").text = str(chunk.lod)
	for x in range(-1, 1):
		for y in range(-1, 1):
			var relative_chunk_coords = Vector2(player_coords.x + x, player_coords.y + y)
			var chunk: Chunk = get_chunk(relative_chunk_coords)
			update_collider(chunk)

func update_mesh(chunk: Chunk, new_lod: int) -> void:
	if chunk.lod != new_lod or chunk.is_new:
		chunk.is_new = false
		chunk.lod = new_lod
		var new_mesh: Mesh = generate_chunk_mesh(chunk.coords, new_lod, chunk.directions_to_downscale)
		chunk.get_node("MeshInstance3D").mesh = new_mesh

func update_collider(chunk: Chunk) -> void:
	var new_collider: ConcavePolygonShape3D = generate_chunk_collision_shape(chunk.coords, 1)
	chunk.get_node("StaticBody3D/CollisionShape3D").shape = new_collider

func get_lod(coords: Vector2) -> int:
	var dist: int = int(max(abs(coords.x), abs(coords.y)))
	if dist <= 1:
		return 0
	elif dist <= 3:
		return 1
	elif dist <= 4:
		return 2
	elif dist <= 5:
		return 3
	else:
		return 4

func get_chunk(coords: Vector2) -> Chunk:
	if chunks.has(coords):
		return chunks[coords]
	var chunk = chunk_scene.instantiate()
	chunk.coords = coords
	chunk.name = "Chunk " + str(int(coords.x)) + "," + str(int(coords.y))
	chunks[coords] = chunk
	get_node("Chunks").add_child(chunk)
	return chunk

func delete_old_chunks(reset_everything: bool = false) -> void:
	var player_coords: Vector2 = get_player_coordinates()
	var i: int = 0
	var to_remove_keys: Array[Vector2] = []

	for key in chunks.keys():
		var chunk: Chunk = chunks[key]
		if reset_everything:
			to_remove_keys.append(key)
			continue
		var chunk_offset: Vector2 = chunk.coords - player_coords
		var distance_from_player: int = int(max(abs(chunk_offset.x), abs(chunk_offset.y)))
		if distance_from_player > unload_radius:
			to_remove_keys.append(key)
			continue
	# do the actual removals in one pass
	for key in to_remove_keys:
		var chunk: Chunk = chunks[key]
		if is_instance_valid(chunk):
			chunk.queue_free()
		chunks.erase(key)

func generate_chunk_mesh(coords: Vector2, lod: int, directions_to_downscale: Array[Vector2]) -> Mesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var lod_step: int = pow(2, lod)
	var pos: Vector2 = coords * chunk_size
	assert(lod_step != 0, "LOD step cannot be zero")
	# chunk
	for y in range(0, chunk_size - lod_step, lod_step):
		for x in range(0, chunk_size - lod_step, lod_step):

			var h1: float = terrain_generator.get_height(pos + Vector2(x, y))
			var h2: float = terrain_generator.get_height(pos + Vector2(x + lod_step, y))
			var h3: float = terrain_generator.get_height(pos + Vector2(x, y + lod_step))
			var h4: float = terrain_generator.get_height(pos + Vector2(x + lod_step, y + lod_step))

			var p1: Vector3 = Vector3(x, h1, y)
			var p2: Vector3 = Vector3(x + lod_step, h2, y)
			var p3: Vector3 = Vector3(x, h3, y + lod_step)
			var p4: Vector3 = Vector3(x + lod_step, h4, y + lod_step)

			var uv1: Vector2 = Vector2(float(x) / chunk_size, float(y) / chunk_size)
			var uv2: Vector2 = Vector2(float(x + lod_step) / chunk_size, float(y) / chunk_size)
			var uv3: Vector2 = Vector2(float(x) / chunk_size, float(y + lod_step) / chunk_size)
			var uv4: Vector2 = Vector2(float(x + lod_step) / chunk_size, float(y + lod_step) / chunk_size)
		
			st.set_uv(uv1); st.add_vertex(p1)
			st.set_uv(uv2); st.add_vertex(p2)
			st.set_uv(uv3); st.add_vertex(p3)
			
			st.set_uv(uv2); st.add_vertex(p2)
			st.set_uv(uv4); st.add_vertex(p4)
			st.set_uv(uv3); st.add_vertex(p3)
	# chunk border
	for direction in directions:
		var adjacent_chunk: Chunk
		if chunks.has(coords + direction):
			adjacent_chunk = chunks.get(coords + direction)
			if direction == Vector2.UP:
				if adjacent_chunk.lod > lod:
					var y = -lod_step * 2
					for x in range(-lod_step * 2, chunk_size, lod_step):
						var h1: float = terrain_generator.get_height(pos + Vector2(x, y))
						var h2: float = terrain_generator.get_height(pos + Vector2(x + lod_step, y))
						var h3: float = terrain_generator.get_height(pos + Vector2(x, y + lod_step))
						var h4: float = terrain_generator.get_height(pos + Vector2(x + lod_step, y + lod_step))
						var h5: float = terrain_generator.get_height(pos + Vector2(x + lod_step * 2, y))
						var p1: Vector3 = Vector3(x, h1, y)
						var p2: Vector3 = Vector3(x + lod_step, h2, y)
						var p3: Vector3 = Vector3(x, h3, y + lod_step)
						var p4: Vector3 = Vector3(x + lod_step, h4, y + lod_step)
						var p5: Vector3 = Vector3(x + lod_step * 2, h5, y)
						var uv1: Vector2 = Vector2(float(x) / chunk_size, float(y) / chunk_size)
						var uv2: Vector2 = Vector2(float(x + lod_step) / chunk_size, float(y) / chunk_size)
						var uv3: Vector2 = Vector2(float(x) / chunk_size, float(y + lod_step) / chunk_size)
						var uv4: Vector2 = Vector2(float(x + lod_step) / chunk_size, float(y + lod_step) / chunk_size)
						var uv5: Vector2 = Vector2(float(x + lod_step * 2) / chunk_size, float(y) / chunk_size)
						# generates left triangles
						if abs(int(x/lod_step)) % 2 == 1:
							if x != chunk_size - lod_step:
								st.set_uv(uv2); st.add_vertex(p2)
								st.set_uv(uv4); st.add_vertex(p4)
								st.set_uv(uv3); st.add_vertex(p3)
						# generates right triangles and main triangle
						if int(x/lod_step) % 2 == 0:
							if x != -lod_step * 2:
								st.set_uv(uv1); st.add_vertex(p1)
								st.set_uv(uv4); st.add_vertex(p4)
								st.set_uv(uv3); st.add_vertex(p3)
							
							st.set_uv(uv4); st.add_vertex(p4)
							st.set_uv(uv1); st.add_vertex(p1)
							st.set_uv(uv5); st.add_vertex(p5)
					
					y = -lod_step
					for x in range(-lod_step * 2, chunk_size - lod_step, lod_step):
						var h1: float = terrain_generator.get_height(pos + Vector2(x, y))
						var h2: float = terrain_generator.get_height(pos + Vector2(x + lod_step, y))
						var h3: float = terrain_generator.get_height(pos + Vector2(x, y + lod_step))
						var h4: float = terrain_generator.get_height(pos + Vector2(x + lod_step, y + lod_step))
						var h5: float = terrain_generator.get_height(pos + Vector2(x + lod_step * 2, y))
						var p1: Vector3 = Vector3(x, h1, y)
						var p2: Vector3 = Vector3(x + lod_step, h2, y)
						var p3: Vector3 = Vector3(x, h3, y + lod_step)
						var p4: Vector3 = Vector3(x + lod_step, h4, y + lod_step)
						var p5: Vector3 = Vector3(x + lod_step * 2, h5, y)
						var uv1: Vector2 = Vector2(float(x) / chunk_size, float(y) / chunk_size)
						var uv2: Vector2 = Vector2(float(x + lod_step) / chunk_size, float(y) / chunk_size)
						var uv3: Vector2 = Vector2(float(x) / chunk_size, float(y + lod_step) / chunk_size)
						var uv4: Vector2 = Vector2(float(x + lod_step) / chunk_size, float(y + lod_step) / chunk_size)
						st.set_uv(uv1); st.add_vertex(p1)
						st.set_uv(uv2); st.add_vertex(p2)
						st.set_uv(uv3); st.add_vertex(p3)
						
						st.set_uv(uv2); st.add_vertex(p2)
						st.set_uv(uv4); st.add_vertex(p4)
						st.set_uv(uv3); st.add_vertex(p3)

				# make equal borders
				if adjacent_chunk.lod == lod:
					var y = -lod_step
					for x in range(-lod_step, chunk_size - lod_step, lod_step):
						var h1: float = terrain_generator.get_height(pos + Vector2(x, y))
						var h2: float = terrain_generator.get_height(pos + Vector2(x + lod_step, y))
						var h3: float = terrain_generator.get_height(pos + Vector2(x, y + lod_step))
						var h4: float = terrain_generator.get_height(pos + Vector2(x + lod_step, y + lod_step))

						var p1: Vector3 = Vector3(x, h1, y)
						var p2: Vector3 = Vector3(x + lod_step, h2, y)
						var p3: Vector3 = Vector3(x, h3, y + lod_step)
						var p4: Vector3 = Vector3(x + lod_step, h4, y + lod_step)

						var uv1: Vector2 = Vector2(float(x) / chunk_size, float(y) / chunk_size)
						var uv2: Vector2 = Vector2(float(x + lod_step) / chunk_size, float(y) / chunk_size)
						var uv3: Vector2 = Vector2(float(x) / chunk_size, float(y + lod_step) / chunk_size)
						var uv4: Vector2 = Vector2(float(x + lod_step) / chunk_size, float(y + lod_step) / chunk_size)
					
						st.set_uv(uv1); st.add_vertex(p1)
						st.set_uv(uv2); st.add_vertex(p2)
						st.set_uv(uv3); st.add_vertex(p3)
						
						st.set_uv(uv2); st.add_vertex(p2)
						st.set_uv(uv4); st.add_vertex(p4)
						st.set_uv(uv3); st.add_vertex(p3)
			if direction == Vector2.LEFT:
				if adjacent_chunk.lod > lod:
					var x = -lod_step * 2
					for y in range(-lod_step * 2, chunk_size - lod_step, lod_step):
						var h1: float = terrain_generator.get_height(pos + Vector2(x, y))
						var h2: float = terrain_generator.get_height(pos + Vector2(x + lod_step, y))
						var h3: float = terrain_generator.get_height(pos + Vector2(x, y + lod_step))
						var h4: float = terrain_generator.get_height(pos + Vector2(x + lod_step, y + lod_step))
						var h5: float = terrain_generator.get_height(pos + Vector2(x, y + lod_step * 2))
						var p1: Vector3 = Vector3(x, h1, y)
						var p2: Vector3 = Vector3(x + lod_step, h2, y)
						var p3: Vector3 = Vector3(x, h3, y + lod_step)
						var p4: Vector3 = Vector3(x + lod_step, h4, y + lod_step)
						var p5: Vector3 = Vector3(x, h5, y + lod_step * 2)
						var uv1: Vector2 = Vector2(float(x) / chunk_size, float(y) / chunk_size)
						var uv2: Vector2 = Vector2(float(x + lod_step) / chunk_size, float(y) / chunk_size)
						var uv3: Vector2 = Vector2(float(x) / chunk_size, float(y + lod_step) / chunk_size)
						var uv4: Vector2 = Vector2(float(x + lod_step) / chunk_size, float(y + lod_step) / chunk_size)
						var uv5: Vector2 = Vector2(float(x) / chunk_size, float(y + lod_step * 2) / chunk_size)
						# generates left triangles
						if abs(int(y/lod_step)) % 2 == 1:
							st.set_uv(uv2); st.add_vertex(p2)
							st.set_uv(uv4); st.add_vertex(p4)
							st.set_uv(uv3); st.add_vertex(p3)
						# generates right triangles and main triangle
						if int(y/lod_step) % 2 == 0:
							if y != -lod_step * 2:
								st.set_uv(uv1); st.add_vertex(p1)
								st.set_uv(uv2); st.add_vertex(p2)
								st.set_uv(uv4); st.add_vertex(p4)
								
							st.set_uv(uv1); st.add_vertex(p1)
							st.set_uv(uv4); st.add_vertex(p4)
							st.set_uv(uv5); st.add_vertex(p5)

					x = -lod_step
					for y in range(0, chunk_size - lod_step, lod_step):
						var h1: float = terrain_generator.get_height(pos + Vector2(x, y))
						var h2: float = terrain_generator.get_height(pos + Vector2(x + lod_step, y))
						var h3: float = terrain_generator.get_height(pos + Vector2(x, y + lod_step))
						var h4: float = terrain_generator.get_height(pos + Vector2(x + lod_step, y + lod_step))
						var p1: Vector3 = Vector3(x, h1, y)
						var p2: Vector3 = Vector3(x + lod_step, h2, y)
						var p3: Vector3 = Vector3(x, h3, y + lod_step)
						var p4: Vector3 = Vector3(x + lod_step, h4, y + lod_step)
						var uv1: Vector2 = Vector2(float(x) / chunk_size, float(y) / chunk_size)
						var uv2: Vector2 = Vector2(float(x + lod_step) / chunk_size, float(y) / chunk_size)
						var uv3: Vector2 = Vector2(float(x) / chunk_size, float(y + lod_step) / chunk_size)
						var uv4: Vector2 = Vector2(float(x + lod_step) / chunk_size, float(y + lod_step) / chunk_size)
						st.set_uv(uv1); st.add_vertex(p1)
						st.set_uv(uv2); st.add_vertex(p2)
						st.set_uv(uv3); st.add_vertex(p3)
						
						st.set_uv(uv2); st.add_vertex(p2)
						st.set_uv(uv4); st.add_vertex(p4)
						st.set_uv(uv3); st.add_vertex(p3)

				# make equal borders
				if adjacent_chunk.lod == lod:
					var x = -lod_step
					for y in range(-lod_step, chunk_size - lod_step, lod_step):
						var h1: float = terrain_generator.get_height(pos + Vector2(x, y))
						var h2: float = terrain_generator.get_height(pos + Vector2(x + lod_step, y))
						var h3: float = terrain_generator.get_height(pos + Vector2(x, y + lod_step))
						var h4: float = terrain_generator.get_height(pos + Vector2(x + lod_step, y + lod_step))

						var p1: Vector3 = Vector3(x, h1, y)
						var p2: Vector3 = Vector3(x + lod_step, h2, y)
						var p3: Vector3 = Vector3(x, h3, y + lod_step)
						var p4: Vector3 = Vector3(x + lod_step, h4, y + lod_step)

						var uv1: Vector2 = Vector2(float(x) / chunk_size, float(y) / chunk_size)
						var uv2: Vector2 = Vector2(float(x + lod_step) / chunk_size, float(y) / chunk_size)
						var uv3: Vector2 = Vector2(float(x) / chunk_size, float(y + lod_step) / chunk_size)
						var uv4: Vector2 = Vector2(float(x + lod_step) / chunk_size, float(y + lod_step) / chunk_size)
						
						st.set_uv(uv1); st.add_vertex(p1)
						st.set_uv(uv2); st.add_vertex(p2)
						st.set_uv(uv3); st.add_vertex(p3)
						
						st.set_uv(uv2); st.add_vertex(p2)
						st.set_uv(uv4); st.add_vertex(p4)
						st.set_uv(uv3); st.add_vertex(p3)

			if direction == Vector2.RIGHT:
				if adjacent_chunk.lod > lod:
					var x = chunk_size - lod_step
					for y in range(-lod_step * 2, chunk_size - lod_step, lod_step):
						var h1: float = terrain_generator.get_height(pos + Vector2(x, y))
						var h2: float = terrain_generator.get_height(pos + Vector2(x + lod_step, y))
						var h3: float = terrain_generator.get_height(pos + Vector2(x, y + lod_step))
						var h4: float = terrain_generator.get_height(pos + Vector2(x + lod_step, y + lod_step))
						var h5: float = terrain_generator.get_height(pos + Vector2(x + lod_step, y + lod_step * 2))
						var p1: Vector3 = Vector3(x, h1, y)
						var p2: Vector3 = Vector3(x + lod_step, h2, y)
						var p3: Vector3 = Vector3(x, h3, y + lod_step)
						var p4: Vector3 = Vector3(x + lod_step, h4, y + lod_step)
						var p5: Vector3 = Vector3(x + lod_step, h5, y + lod_step * 2)
						var uv1: Vector2 = Vector2(float(x) / chunk_size, float(y) / chunk_size)
						var uv2: Vector2 = Vector2(float(x + lod_step) / chunk_size, float(y) / chunk_size)
						var uv3: Vector2 = Vector2(float(x) / chunk_size, float(y + lod_step) / chunk_size)
						var uv4: Vector2 = Vector2(float(x + lod_step) / chunk_size, float(y + lod_step) / chunk_size)
						var uv5: Vector2 = Vector2(float(x + lod_step) / chunk_size, float(y + lod_step * 2) / chunk_size)
						# generates left triangles
						if abs(int(y/lod_step)) % 2 == 1:
							st.set_uv(uv1); st.add_vertex(p1)
							st.set_uv(uv4); st.add_vertex(p4)
							st.set_uv(uv3); st.add_vertex(p3)
						# generates right triangles and main triangle
						if int(y/lod_step) % 2 == 0:
							if y != -lod_step * 2:
								st.set_uv(uv2); st.add_vertex(p2)
								st.set_uv(uv3); st.add_vertex(p3)
								st.set_uv(uv1); st.add_vertex(p1)
							
							st.set_uv(uv3); st.add_vertex(p3)
							st.set_uv(uv2); st.add_vertex(p2)
							st.set_uv(uv5); st.add_vertex(p5)
			if direction == Vector2.DOWN:
				if adjacent_chunk.lod > lod:
					var y = chunk_size - lod_step
					for x in range(-lod_step * 2, chunk_size - lod_step, lod_step):
						var h1: float = terrain_generator.get_height(pos + Vector2(x, y))
						var h2: float = terrain_generator.get_height(pos + Vector2(x + lod_step, y))
						var h3: float = terrain_generator.get_height(pos + Vector2(x, y + lod_step))
						var h4: float = terrain_generator.get_height(pos + Vector2(x + lod_step, y + lod_step))
						var h5: float = terrain_generator.get_height(pos + Vector2(x + lod_step * 2, y + lod_step))
						var p1: Vector3 = Vector3(x, h1, y)
						var p2: Vector3 = Vector3(x + lod_step, h2, y)
						var p3: Vector3 = Vector3(x, h3, y + lod_step)
						var p4: Vector3 = Vector3(x + lod_step, h4, y + lod_step)
						var p5: Vector3 = Vector3(x + lod_step * 2, h5, y + lod_step)
						var uv1: Vector2 = Vector2(float(x) / chunk_size, float(y) / chunk_size)
						var uv2: Vector2 = Vector2(float(x + lod_step) / chunk_size, float(y) / chunk_size)
						var uv3: Vector2 = Vector2(float(x) / chunk_size, float(y + lod_step) / chunk_size)
						var uv4: Vector2 = Vector2(float(x + lod_step) / chunk_size, float(y + lod_step) / chunk_size)
						var uv5: Vector2 = Vector2(float(x + lod_step * 2) / chunk_size, float(y + lod_step) / chunk_size)
						# generates left triangles
						if abs(int(x/lod_step)) % 2 == 1:
							st.set_uv(uv1); st.add_vertex(p1)
							st.set_uv(uv2); st.add_vertex(p2)
							st.set_uv(uv4); st.add_vertex(p4)
						# generates right triangles and main triangle
						if int(x/lod_step) % 2 == 0:
							if x != -lod_step * 2:
								st.set_uv(uv1); st.add_vertex(p1)
								st.set_uv(uv2); st.add_vertex(p2)
								st.set_uv(uv3); st.add_vertex(p3)
							st.set_uv(uv3); st.add_vertex(p3)
							st.set_uv(uv2); st.add_vertex(p2)
							st.set_uv(uv5); st.add_vertex(p5)

	#TODO reactivate normals
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
