extends CanvasLayer

var pause_menu_opened = false

func _ready():
	close_pause_menu()

func _on_resume_button_pressed() -> void:
	close_pause_menu()

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func open_pause_menu() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	pause_menu_opened = true
	visible = true

func close_pause_menu() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	pause_menu_opened = false
	visible = false

func toggle_pause_menu() -> void:
	if pause_menu_opened:
		close_pause_menu()
	else:
		open_pause_menu()

func _on_set_time_pressed() -> void:
	var text = get_node("VBoxContainer/HBoxContainer/TextEdit").text
	if text.is_valid_int():
		get_tree().get_first_node_in_group("world").get_node("GameManager").set_time(int(text))
	get_node("VBoxContainer/HBoxContainer/TextEdit").text = ""
