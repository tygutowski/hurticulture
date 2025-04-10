extends Item

const SHELL_LIFETIME = 10
var barrel_open_rotation: Vector3 = Vector3(0, 0, -15)
@onready var barrel_pivot = get_node("BarrelPivot")
@onready var animation_player: AnimationPlayer = get_node("AnimationPlayer")

func reload() -> void:
	animation_player.play("reload")

func eject_shell() -> void:
	var shell: MeshInstance3D = load("res://ShotgunShell.tscn").instantiate()
	get_tree().get_first_node_in_group("world").get_node("WorldGenerator/Items").add_child(shell)
	
	var timer = Timer.new()
	timer.start(SHELL_LIFETIME)
	timer.connect("timeout", kill_shell.bind(shell))

func kill_shell(shell) -> void:
	shell.queue_free()
