extends Resource
class_name BiomeParticle

var enabled: bool = false
var cast_shadow: GeometryInstance3D.ShadowCastingSetting = GeometryInstance3D.ShadowCastingSetting.SHADOW_CASTING_SETTING_OFF
var aabb: AABB = AABB(Vector3(-10000, -500, -10000), Vector3(20000, 1000, 20000))

@export var amount: int = 1000
@export var lifetime: float = 3
@export var particle_material: ParticleProcessMaterial
@export var particle_mesh: Mesh = load("res://environment/DefaultParticleMesh.tres")
