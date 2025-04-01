@tool
extends Node3D

@export var viewport: SubViewport
@onready var screen_mesh: MeshInstance3D = get_node("ComputerMesh/ScreenMesh")


func _ready() -> void:
	if viewport != null:
		screen_mesh.get_surface_override_material(0).albedo_texture.viewport_path = get_path_to(viewport)
