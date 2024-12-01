extends Node3D

func _process(_float):
	var material = get_node("MeshInstance3D").get_active_material(0)
	material.albedo_color.a = .8
