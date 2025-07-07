extends Item

const SHELL_LIFETIME = 10
var max_ammo: int = 10000
var ammo: int = max_ammo
var barrel_open_rotation: Vector3 = Vector3(0, 0, -15)
var pellet_count: int = 10

@export var ammo_scene: PackedScene
@onready var barrel_pivot = get_node("BarrelPivot")
var can_shoot: bool = true

func reload_item() -> void:
	if ammo != max_ammo:
		animation_player.play("reload")
		get_node("Audio/Reloading").play()

func finish_reloading() -> void:
	can_shoot = true

func start_reloading() -> void:
	can_shoot = false

func eject_shell() -> void:
	var shell: RigidBody3D = load("res://ShotgunShell.tscn").instantiate()
	get_tree().get_first_node_in_group("world").get_node("Items").add_child(shell)
	
	var timer = Timer.new()
	timer.start(SHELL_LIFETIME)
	timer.connect("timeout", kill_shell.bind(shell))

func kill_shell(shell) -> void:
	shell.queue_free()

# pull trigger
func use_item() -> void:
	if can_shoot:
		if ammo > 0:
			shoot()
		else:
			get_node("Audio/Empty").play()

func shoot() -> void:
	get_node("Audio/Shooting").volume_db = randf_range(-1, 1)
	get_node("Audio/Shooting").pitch_scale = randf_range(0.8, 1.2)
	get_node("Audio/Shooting").play()
	for pellet in pellet_count:
		var raycast: RayCast3D = get_node("Muzzle/RayCast3D")
		raycast.target_position.y = randf_range(-8, 8)
		raycast.target_position.z = randf_range(-8, 8)
		raycast.force_raycast_update()
		if raycast.is_colliding():
			var collision_point = raycast.get_collision_point()
			Debug.debug("collided at " + str(collision_point))
			var hole_decal_scene: PackedScene = load("res://ShotgunBulletHole.tscn")
			var hole_decal: Decal = hole_decal_scene.instantiate()
			get_tree().get_first_node_in_group("world").add_child(hole_decal)
			hole_decal.global_position = collision_point
		
	ammo -= 1

func add_shell_to_chamber() -> void:
	#ammo = min(ammo + 1, max_ammo)
	ammo = max_ammo
