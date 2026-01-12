extends CanvasLayer

var dev_menu_opened: bool = false

func _ready() -> void:
	visible = false
	var env: Environment = get_tree().get_first_node_in_group("world").get_node("WorldEnvironment").environment
	env.fog_enabled = true
	env.volumetric_fog_enabled = true

func open_dev_menu() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	dev_menu_opened = true
	visible = true

func close_dev_menu() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	dev_menu_opened = false
	visible = false

func toggle_dev_menu() -> void:
	if dev_menu_opened:
		close_dev_menu()
	else:
		open_dev_menu()

func _on_fog_button_pressed() -> void:
	var env: Environment = get_tree().get_first_node_in_group("world").get_node("WorldEnvironment").environment
	env.fog_enabled = not env.fog_enabled
	env.volumetric_fog_enabled = not env.volumetric_fog_enabled
