@tool
class_name TerrainChunk
extends MeshInstance3D

@export_range(20, 400, 1) var terrain_size := 200
@export_range(1, 100, 1) var resolution := 20
@export var terrain_max_height = 5

@export var chunk_lods : Array[int] = [2,4,8,15,20,50]
@export var LOD_distances : Array[int] = [2000,1500,1050,900,790,550]

var position_coord = Vector2()
var grid_coord = Vector2()

const CENTER_OFFSET = 0.5

var set_collision = false

func generate_terrain(mountain_noise : FastNoiseLite,
					  coords                      : Vector2,
					  size                        : float,
					  initially_visible           : bool):
	terrain_size = size
	grid_coord = coords
	position_coord = coords * size
	
	var a_mesh : ArrayMesh
	var surftool = SurfaceTool.new()
	surftool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for z in resolution + 1:
		for x in resolution + 1:
			var percent = Vector2(x,z)/resolution
			
			var point_on_mesh = Vector3((percent.x - CENTER_OFFSET), 0, (percent.y - CENTER_OFFSET))
			
			var mountain_vertex  = point_on_mesh * terrain_size
			mountain_vertex.y = mountain_noise.get_noise_2d(
				position.x + mountain_vertex.x,
				position.z + mountain_vertex.z) * terrain_max_height
			var vertex = (mountain_vertex)
			var uv = Vector2()
			
			uv.x = percent.x
			uv.y = percent.y
			
			surftool.set_uv(uv)
			surftool.add_vertex(vertex)
	
	var vert = 0
	for z in resolution:
		for x in resolution:
			surftool.add_index(vert + 0)
			surftool.add_index(vert + 1)
			surftool.add_index(vert + resolution + 1)
			surftool.add_index(vert + resolution +  1)
			surftool.add_index(vert + 1)
			surftool.add_index(vert + resolution +  2)
			vert += 1
		vert += 1
	
	surftool.generate_normals()
	a_mesh = surftool.commit()
	mesh = a_mesh
	
	if set_collision:
		create_collision()
	set_chunk_visibility(initially_visible)

func create_collision():
	if get_child_count() > 0:
		get_child(0).queue_free()
	create_trimesh_collision()

func update_chunk(view_pos : Vector2, max_view_dis : float):
	var viewer_distance = position_coord.distance_to(view_pos)
	var is_visible = viewer_distance <= max_view_dis

func should_remove(view_pos : Vector2, max_view_dis : float):
	var remove = false
	var viewer_distance = position_coord.distance_to(view_pos)
	if viewer_distance > max_view_dis:
		remove = true
	return remove

func update_lod(view_pos : Vector2):
	var viewer_distance = position_coord.distance_to(view_pos)
	var update_terrain = false
	var new_lod = chunk_lods[0]
	if chunk_lods.size() != LOD_distances.size():
		Debug.debug("Error: LODs and distance count mismatch")
		return
	for i in range(chunk_lods.size()):
		var lod = chunk_lods[i]
		var distance = LOD_distances[i]
		if viewer_distance < distance:
			new_lod = lod
	
	if new_lod >= chunk_lods[chunk_lods.size() - 1]:
		set_collision = true
	else:
		set_collision = false
	
	if resolution != new_lod:
		resolution = new_lod
		update_terrain = true
	return update_terrain

func free_chunk():
	queue_free()

func set_chunk_visibility(is_visible : bool):
	visible = is_visible

func get_chunk_visibility():
	return visible
