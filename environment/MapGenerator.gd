extends Node
class_name MapGenerator

@export_category("Terrain Generation")
var chunk_size: int = 24
var subchunks_per_chunk: int = 8
var generate_radius: int = 12
var unload_radius: int = 12
var subchunk_length: int = chunk_size / subchunks_per_chunk
var current_biome: Biome = null
var generated_spawn: bool = false
var shape_cast: ShapeCast3D
var directions: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
var chunks: Dictionary[Vector2, Chunk] = {}

@onready var chunk_scene: PackedScene = load("res://world_generation/Chunk.tscn")
@onready var terrain_generator: TerrainGenerator = get_node("TerrainGenerator")
@onready var biome_generator: BiomeGenerator = get_node("BiomeGenerator")
@onready var flora_generator: FloraGenerator = get_node("FloraGenerator")
@onready var object_generator: ObjectGenerator = get_node("ObjectGenerator")
@onready var flat_array: Texture2DArray = make_flat_texture_array(biome_generator.biome_list)

@onready var chunks_node: Node = get_node("Chunks")

var player: Player

var explored_chunks: Dictionary[Vector2, Chunk] = {}
var chunks_pending: Dictionary[Vector2, bool] = {}
var chunks_to_generate: Array[Vector2] = []

var biome_update_timer: float = 0
var biome_update_timer_threshold: float = 0.5

var last_chunk: Vector2 = Vector2.INF

var needed_cache: Array[Vector2] = []
var needed_cache_center: Vector2 = Vector2.INF

var player_coords: Vector2 = Vector2.ZERO
@export var chunks_per_frame: int = 4

func _ready() -> void:
	var radius: int = 1
	var ship: Node3D = load("res://ship/Ship.tscn").instantiate()
	shape_cast = ship.get_node("ShapeCast3D")
	add_child(ship)
	while true:
		for x: int in range(-radius, radius + 1):
			for y: int in range(-radius, radius + 1):
				var coords: Vector2 = Vector2(x, y)
				if not chunks.has(coords):
					await create_chunk(coords)
					ship.get_node("Anchors").max_distance_to_floor += 0.0001

				# only place if this chunk can support the ship footprint
				if not has_chunk_neighborhood(coords, 1):
					continue

				var chunk: Chunk = chunks[coords]
				if await attempt_to_place(ship, chunk):
					var spawn_point: Vector3 = ship.get_node("SpawnPoint").global_position
					var spawn_chunk_coords: Vector2 = Vector2(
						floor(spawn_point.x / chunk_size),
						floor(spawn_point.z / chunk_size)
					)

					#TODO Add something to indicate to the player that the world is actively generating
					# await preload_chunks_around(spawn_chunk_coords)

					update_visible_chunks(spawn_chunk_coords)

					player = load("res://player/Player.tscn").instantiate()
					add_child(player)
					player.global_position = spawn_point
					return
		radius += 1

func preload_chunks_around(center: Vector2) -> void:
	var needed: Array[Vector2] = get_chunks_in_radius_around(center)

	# Force-generate everything synchronously
	for coords: Vector2 in needed:
		if not chunks.has(coords):
			await create_chunk(coords)

	# Wait until nothing is pending or queued
	while not chunks_to_generate.is_empty() or not chunks_pending.is_empty():
		await get_tree().process_frame


func has_chunk_neighborhood(center: Vector2, radius: int) -> bool:
	for dx: int in range(-radius, radius + 1):
		for dy: int in range(-radius, radius + 1):
			if not chunks.has(center + Vector2(dx, dy)):
				return false
	return true


func attempt_to_place(node: Node3D, chunk: Chunk) -> bool:
	for attempt: int in range(20):
		print("")
		# random yaw on ship ONLY
		node.rotation.y = randf_range(0.0, TAU)
		await get_tree().physics_frame

		# place ship so shapecast starts above chunk
		var local_cast: Vector3 = shape_cast.position
		node.global_position = Vector3(
			chunk_size * chunk.coords.x + randi_range(0, chunk_size),
			1000.0,
			chunk_size * chunk.coords.y + randi_range(0, chunk_size)
		) - node.global_transform.basis * local_cast

		shape_cast.target_position = Vector3.DOWN * 2000.0
		shape_cast.force_shapecast_update()

		if not shape_cast.is_colliding():
			continue

		await get_tree().physics_frame

		var cast_vector: Vector3 = shape_cast.target_position
		var t: float = shape_cast.get_closest_collision_safe_fraction()

		# move ship so shapecast touches ground
		node.global_position += cast_vector * t + Vector3(0, 1, 0)

		var valid: bool = true
		var anchors: Array[Node] = node.get_node("Anchors").get_children()
		var anti_anchors: Array[Node] = node.get_node("AntiAnchors").get_children()
		if anchors.is_empty():
			valid = false
		for anchor_node: Node in anchors:
			var anchor: Node3D = anchor_node as Node3D
			$ObjectRayCast3D.global_position = anchor.global_position
			$ObjectRayCast3D.force_raycast_update()

			if not $ObjectRayCast3D.is_colliding():
				valid = false
				break

			var y: float = $ObjectRayCast3D.get_collision_point().y
			if abs(anchor.global_position.y - y) >= node.get_node("Anchors").max_distance_to_floor:
				valid = false
				break
		for anti_anchor: Node in anti_anchors:
			$ObjectRayCast3D.global_position = anti_anchor.global_position
			$ObjectRayCast3D.force_raycast_update()

			if $ObjectRayCast3D.is_colliding():
				valid = false
				break
		if valid:
			return true

	return false

func process_chunk_queue() -> void:
	var count: int = 0
	while chunks_to_generate.size() > 0 and count < chunks_per_frame:
		var coords: Vector2 = chunks_to_generate.pop_front()

		# Was loaded meanwhile
		if chunks.has(coords):
			chunks_pending.erase(coords)
			continue

		await create_chunk(coords)
		count += 1

func update_visible_chunks(center_coords: Vector2) -> void:
	var needed: Array[Vector2] = get_chunks_in_radius_around(center_coords)

	for coords: Vector2 in needed:
		# Already active → nothing to do
		if chunks.has(coords):
			continue

		# Explored before → load instantly
		if explored_chunks.has(coords):
			var chunk: Chunk = explored_chunks[coords]
			chunks[coords] = chunk
			chunks_node.add_child(chunk)
			continue

		# New chunk → queue generation
		if not chunks_pending.has(coords):
			chunks_pending[coords] = true
			chunks_to_generate.append(coords)

	# Unload unused
	var to_unload: Array[Vector2] = []
	for coords: Vector2 in chunks.keys():
		if coords not in needed and not chunks_pending.has(coords):
			to_unload.append(coords)

	for coords: Vector2 in to_unload:
		unload_chunk(coords)


func cleanup_stragglers() -> void:
	var needed: Array[Vector2] = get_chunks_in_radius_around(player_coords)

	var to_remove: Array[Vector2] = []
	for coords: Vector2 in chunks.keys():
		# If chunk is not needed and not queued for generation, remove it
		if coords not in needed and coords not in chunks_to_generate:
			to_remove.append(coords)

	for coords: Vector2 in to_remove:
		var chunk: Chunk = chunks[coords]
		if is_instance_valid(chunk):
			chunks_node.remove_child(chunk)
		chunks.erase(coords)


func _process(delta) -> void:
	biome_update_timer += delta
	if biome_update_timer >= biome_update_timer_threshold and player != null:
		biome_update_timer -= biome_update_timer_threshold
		update_biome()
	if player == null:
		return
	update_player_coordinates()
	var current_chunk: Vector2 = player_coords
	process_chunk_queue()
	cleanup_stragglers()
	if current_chunk != last_chunk and not player.freeze_map:
		update_visible_chunks(player_coords)

		last_chunk = current_chunk
	
func update_player_coordinates() -> void:
	player_coords = Vector2(
		floor(player.global_position.x/chunk_size),
		floor(player.global_position.z/chunk_size)
	)

func get_chunks_in_radius_around(chunk_coords: Vector2) -> Array[Vector2]:
	if chunk_coords == needed_cache_center:
		return needed_cache

	needed_cache_center = chunk_coords
	needed_cache.clear()

	for x_offset: int in range(-generate_radius, generate_radius + 1):
		for y_offset: int in range(-generate_radius, generate_radius + 1):
			needed_cache.append(chunk_coords + Vector2(x_offset, y_offset))

	return needed_cache

func update_biome() -> void:
	var cx: int = floor(player.global_position.x / chunk_size)
	var cy: int = floor(player.global_position.z / chunk_size)
	var chunk_coords := Vector2(cx, cy)

	if not chunks.has(chunk_coords):
		return

	var chunk := chunks[chunk_coords]

	var wx: float = player.global_position.x
	var wy: float = player.global_position.z

	var biome: Biome = chunk.get_biome_at_world_pos(
		wx,
		wy,
		chunk,
		chunk_size,
		subchunks_per_chunk
	)

	
	if current_biome != biome:
		var env: Environment = get_node("../WorldEnvironment").environment
		
		var tween: Tween = get_tree().create_tween()
		tween.tween_property(
			env,
			"fog_light_color",
			biome.fog_color,
			0.6
		)
		tween.tween_property(
			env,
			"volumetric_fog_albedo",
			biome.fog_color,
			0.6
		)
		tween.tween_property(
			env,
			"volumetric_fog_density",
			biome.fogStrength[biome.fog_intensity],
			0.6
		)
		for particle in player.get_node("NewParticles").get_children():
			particle.queue_free();
		for particle in biome.particles:
			var new_particle: GPUParticles3D = GPUParticles3D.new()
			new_particle.amount = particle.amount
			new_particle.lifetime = particle.lifetime
			new_particle.visibility_aabb = particle.aabb
			new_particle.cast_shadow = particle.cast_shadow
			new_particle.process_material = particle.particle_material
			new_particle.draw_pass_1 = particle.particle_mesh
			player.get_node("NewParticles").add_child(new_particle)
		current_biome = biome

func unload_chunk(coords: Vector2) -> void:
	var chunk: Chunk = chunks[coords]
	if is_instance_valid(chunk):
		chunks_node.remove_child(chunk)
	chunks.erase(coords)

func create_chunk(coords: Vector2) -> Chunk:
	var chunk: Chunk
	if explored_chunks.has(coords):
		chunk = explored_chunks[coords]
		chunks[coords] = chunk
		chunks_node.add_child(chunk)
	else:
		chunk = chunk_scene.instantiate()
		chunks_node.add_child(chunk)
		chunk.coords = coords
		chunk.name = "Chunk %s,%s" % [coords.x, coords.y]
		chunk.global_position = Vector3(coords.x * chunk_size, 0, coords.y * chunk_size)
		explored_chunks[coords] = chunk
		chunks[coords] = chunk
		#await chunk.chunk_ready

		generate_chunk_mesh_and_collider(chunk)

		terrain_generator.generate_chunk_data(chunk)
		chunk.visible = false
		await get_tree().physics_frame
		chunk.visible = true
		if !is_instance_valid(chunk):
			if chunks_pending.has(coords):
				chunks_pending.erase(coords)
			return

		chunk.flat_array = flat_array
		apply_biome_data_to_chunk(chunk, biome_generator.biome_list)
		#fix these to be attached to the chunk
		flora_generator.generate_grass(chunk)
		object_generator.spawn_objects(chunk)
	# Always clear pending
	if chunks_pending.has(coords):
		chunks_pending.erase(coords)

	# If finished too late → discard
	if coords not in get_chunks_in_radius_around(player_coords):
		if is_instance_valid(chunk):
			explored_chunks[coords] = chunk
		if chunks_node.has_node(NodePath(chunk.name)):
			chunks_node.remove_child(chunk)
		chunks.erase(coords)
	return chunk
# make textures into an array to pass into the terrain shader
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


func apply_biome_data_to_chunk(chunk: Chunk, biome_list: Array[Biome]) -> void:
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

func generate_chunk_mesh_and_collider(chunk: Chunk) -> void:
	var pos: Vector2 = chunk.coords * chunk_size

	var heights: Array[Array] = []
	for y in range(0, subchunks_per_chunk + 1):
		var row: Array[float] = []
		for x in range(0, subchunks_per_chunk + 1):
			var wx: float = pos.x + x * subchunk_length
			var wy: float = pos.y + y * subchunk_length
			row.append(terrain_generator.get_height(Vector2(wx, wy)))
		heights.append(row)
	
	var st := SurfaceTool.new()
	var faces := PackedVector3Array()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for y: int in range(subchunks_per_chunk):
		for x: int in range(subchunks_per_chunk):
			var h1: float = heights[y][x]
			var h2: float = heights[y][x + 1]
			var h3: float = heights[y + 1][x]
			var h4: float = heights[y + 1][x + 1]

			var px: float = x * subchunk_length
			var py: float = y * subchunk_length

			var p1 := Vector3(px, h1, py)
			var p2 := Vector3(px + subchunk_length, h2, py)
			var p3 := Vector3(px, h3, py + subchunk_length)
			var p4 := Vector3(px + subchunk_length, h4, py + subchunk_length)

			var uvx: float = px / float(chunk_size)
			var uvy: float = py / float(chunk_size)
			var uv_step: float = subchunk_length / float(chunk_size)

			var uv1 := Vector2(uvx, uvy)
			var uv2 := Vector2(uvx + uv_step, uvy)
			var uv3 := Vector2(uvx, uvy + uv_step)
			var uv4 := Vector2(uvx + uv_step, uvy + uv_step)

			st.set_uv(uv1); st.add_vertex(p1)
			st.set_uv(uv2); st.add_vertex(p2)
			st.set_uv(uv3); st.add_vertex(p3)

			st.set_uv(uv2); st.add_vertex(p2)
			st.set_uv(uv4); st.add_vertex(p4)
			st.set_uv(uv3); st.add_vertex(p3)
			faces.append_array([p1, p2, p3])
			faces.append_array([p2, p4, p3])
	st.generate_normals()
	chunk.get_node("TerrainMesh").mesh = st.commit()
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	chunk.get_node("TerrainCollider/CollisionShape3D").shape = shape
	await get_tree().physics_frame
