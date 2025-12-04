extends Resource
class_name Biome

@export_category("Generics")
@export var id: Global.biomeEnum = Global.biomeEnum.NONE
@export var biome_name: String = "Generic Biome Name"
@export var biome_color: Color = Color.BLACK

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

@export var custom_generation: FastNoiseLite
@export var feature: BiomeFeature = BiomeFeature.NONE

@export_category("Particles")
@export var particles: Array[BiomeParticle]
