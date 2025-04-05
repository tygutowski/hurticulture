@tool
extends Node3D

@export var viewport: SubViewport

func _ready() -> void:
	if viewport != null:
		var mesh: Mesh = get_node("ComputerMesh/ScreenMesh").mesh
		var surface = mesh.surface_get_material(0)
		surface.albedo_texture.viewport_path = get_path_to(viewport)
