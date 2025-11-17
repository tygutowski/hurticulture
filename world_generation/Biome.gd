extends Resource
class_name Biome

@export var id: Global.biomeEnum

@export var biome_name: String = "Default Name"
@export var fog_color: Color = Color(0, 0, 0)

@export var flat_texture: Texture
@export var sloped_texture: Texture

enum BiomeFeature {
	NONE,
	FLOATING_STRUCTURES,
	OBELISKS,
}

@export var feature: BiomeFeature = BiomeFeature.NONE
