extends MeshInstance3D

const SURFACE_INDEX: int = 0

var vertices: PackedVector3Array = PackedVector3Array()
var arrays: Array = []
var arr_mesh: ArrayMesh
var t: float = 0.0

func _ready() -> void:
	vertices.push_back(Vector3(0.0, 1.0, 0.0))
	vertices.push_back(Vector3(1.0, 0.0, 0.0))
	vertices.push_back(Vector3(0.0, 0.0, 1.0))

	arr_mesh = ArrayMesh.new()

	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = arr_mesh

func _process(delta: float) -> void:
	t += delta
	vertices[0] = Vector3(0.0, sin(t * 10.0), 0.0)

	# Push only the vertex buffer bytes; no new surfaces.
	var bytes: PackedByteArray = vertices.to_byte_array()
	arr_mesh.surface_update_vertex_region(SURFACE_INDEX, 0, bytes)
