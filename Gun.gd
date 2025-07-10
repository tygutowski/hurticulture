class_name Gun
extends Item

@export var single_reload: bool = false # for reloading things like pump shotguns or revolvers
@export var is_hitscan: bool = true
@export var is_automatic: bool = false

@export var recoil_strength: float = 5
@export var muzzle_flash_energy: float = 1.0
@export var spent_casing_scene: PackedScene

@export var default_flash_size: float = 0.1
@export var flash_bound: float = 0.01

@export var casing_lifetime: float = 60.0
@export var casing_spawner: Node3D = null

@export var bullet_hole_texture: Texture = preload("res://shotgun_hole_decal.png")
@export var projectile_damage: float = 5

@export var max_ammo: int
var ammo: int

var currently_reloading: bool = false

func fire_projectile() -> void:
	push_error("You must override fire_projectile() in a subclass of Gun.")

func _ready() -> void:
	super._ready()
	hide_muzzle_flashes()
	ammo = max_ammo

func reload_item() -> void:
	if ammo != max_ammo:
		viewport_counterpart.animation_player.play("reload")
		viewport_counterpart.get_node("Audio/Reloading").play()
		ammo = max_ammo

func finish_reloading() -> void:
	currently_reloading = false

func start_reloading() -> void:
	currently_reloading = true

func enable_muzzle_flash() -> void:
	var flash: Sprite3D = null
	if viewport_type == viewportType.FIRSTPERSON:
		flash = get_node_or_null("Animatables/MuzzleFlashLocal")
		get_node("Animatables/MuzzleLightLocal").light_energy = muzzle_flash_energy
	if viewport_type == viewportType.REALWORLD:
		flash = get_node_or_null("Animatables/MuzzleFlashGlobal")
		get_node("Animatables/MuzzleLightGlobal").light_energy = muzzle_flash_energy
		viewport_counterpart.enable_muzzle_flash()
	flash.offset = Vector2(randf_range(-15, 15), randf_range(-15, 15))
	var random_flash_scaling = randf_range(default_flash_size + flash_bound, default_flash_size - flash_bound)
	flash.flip_h = randi_range(0, 1)
	flash.flip_v = randi_range(0, 1)
	flash.scale = Vector3(random_flash_scaling, random_flash_scaling, random_flash_scaling)
	flash.visible = true
	var timer = get_tree().create_timer(0.1)
	timer.connect("timeout", Callable(self, "hide_muzzle_flashes"))

func hide_muzzle_flashes() -> void:
	var flash: Sprite3D = null
	get_node("Animatables/MuzzleLightLocal").light_energy = 0
	get_node("Animatables/MuzzleLightGlobal").light_energy = 0
	flash = get_node_or_null("Animatables/MuzzleFlashGlobal")
	if flash != null:
		flash.visible = false
	flash = get_node_or_null("Animatables/MuzzleFlashLocal")
	if flash != null:
		flash.visible = false


func eject_spent_casing() -> void:
	var casing: RigidBody3D = spent_casing_scene.instantiate()
	get_tree().get_first_node_in_group("world").add_child(casing)
	casing.global_position = casing_spawner.global_position
	casing.apply_central_impulse(global_basis.z + Vector3(-3,2,0))
	var timer = Timer.new()
	timer.start(casing_lifetime)
	timer.connect("timeout", despawn_casing.bind(casing))

func despawn_casing(casing) -> void:
	casing.queue_free()

func update_interval() -> void:
	shoot()

# pull trigger
func use_item() -> void:
	shoot()

func shoot() -> void:
	Debug.debug("Pew!")
	if currently_reloading:
		if single_reload:
			animation_player.play("cancel_reload")
	else:
		if ammo > 0:
			recoil()
			enable_muzzle_flash()
			get_node("Audio/Shooting").volume_db = randf_range(-1, 1)
			get_node("Audio/Shooting").pitch_scale = randf_range(0.8, 1.2)
			get_node("Audio/Shooting").play()
			fire_projectile()
			ammo -= 1
		else:
			get_node("Audio/Empty").play()

func recoil_viewport() -> void:
	get_node("AnimationPlayer").play("shoot")
	get_node("AnimationPlayer").seek(0)

func recoil() -> void:
	viewport_counterpart.recoil_viewport()
	var player: CharacterBody3D = thing_holding_me
	var head: Node3D = player.get_node("Head")
	var head_y_pivot = head.get_node("HeadGameplay")
	head_y_pivot.rotate_y(
		randf_range(
			deg_to_rad(-2.0),
			deg_to_rad(2.0)
		))
	var head_x_pivot = head_y_pivot.get_node("HeadPivot")
	head_x_pivot.rotate_x(deg_to_rad(recoil_strength))
	player.update_head_rotation()
