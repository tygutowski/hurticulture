extends Node3D

@export var chunk_size: Vector2
@export var map_size: Vector2
@export var grass_mesh_high: Mesh
@export var grass_mesh_low: Mesh

const LOD_RADIUS := 1
const LOD_UPDATE_INTERVAL := 0.5

var chunk_count_x: int
var chunk_count_y: int
var lod_timer: float = 0.0
var previous_player_chunk := Vector2i(-999, -999)

func _ready():
	chunk_count_x = int(map_size.x / chunk_size.x)
	chunk_count_y = int(map_size.y / chunk_size.y)

func _process(delta):
	lod_timer += delta
	if lod_timer < LOD_UPDATE_INTERVAL:
		return
	lod_timer = 0.0

	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var player_chunk = check_player_chunk(player.global_position)
	print(player_chunk)
	# Skip if still in the same chunk
	if player_chunk == previous_player_chunk:
		return
	previous_player_chunk = player_chunk

	# Update LODs based on distance from player
	var map_node = get_tree().get_first_node_in_group("map")

	for y in chunk_count_y:
		for x in chunk_count_x:
			var node_name = "MeshInstance%d:%d" % [x, y]
			var mesh_node = map_node.get_node_or_null(node_name)
			if mesh_node == null:
				continue

			var dist = abs(x - player_chunk.x) + abs(y - player_chunk.y)
			var target_mesh = grass_mesh_high if (dist <= LOD_RADIUS) else grass_mesh_low

			if mesh_node.multimesh.mesh != target_mesh:
				mesh_node.multimesh.mesh = target_mesh

func check_player_chunk(world_pos: Vector3) -> Vector2i:
	var local_pos = Vector2(world_pos.x, world_pos.z) + (map_size / 2.0)

	var x_index = int(floor(local_pos.x / chunk_size.x))
	var y_index = int(floor(local_pos.y / chunk_size.y))

	x_index = clamp(x_index, 0, chunk_count_x - 1)
	y_index = clamp(y_index, 0, chunk_count_y - 1)

	return Vector2i(x_index, y_index)
