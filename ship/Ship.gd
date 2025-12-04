extends Node3D

@export var primary_color: Color
@export var secondary_color: Color

@export var exterior_material: StandardMaterial3D
@export var engine_material: StandardMaterial3D


enum decalEnum {
	NONE,
	SKULLS
}

@export var shipDecal: decalEnum = decalEnum.NONE

func _ready() -> void:
	set_paintjob()

func set_paintjob() -> void:
	var decals = get_tree().get_nodes_in_group("ship_decal")
	for decal in decals:
		set_decal(decal)
	exterior_material.albedo_color = primary_color
	engine_material.albedo_color = secondary_color

func set_decal(decal) -> void:
	if shipDecal == decalEnum.NONE:
		decal.visible = false
	else:
		decal.visible = true
	if shipDecal == decalEnum.SKULLS:
		decal.texture_albedo = load("res://ship/decals/skullDecal.png") as CompressedTexture2D
