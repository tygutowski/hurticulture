extends Resource
class_name Biome

@export_category("Generics")
@export var id: Global.biomeEnum = -1
@export var biome_name: String = "Generic Biome Name"

@export_category("Fog")
@export var fog_color: Color = Color(0, 0, 0)
@export var fog_strength: float

@export_category("Terrain")
@export var flat_texture: Texture
@export var sloped_texture: Texture

@export_category("Generations")
enum BiomeFeature {
	NONE,
	FLOATING_STRUCTURES,
	OBELISKS,
}

@export var feature: BiomeFeature = BiomeFeature.NONE

@export_category("Particles")
@export var particle: Mesh
