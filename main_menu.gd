extends Control

@onready var scroll_containers = get_node("OptionsVBox/MarginContainer2/VBoxContainer/VBoxContainer/ScrollContainers")

func _ready() -> void:
	set_default_visibility()
	var window_size = get_viewport().size.y
	for scroll_container in scroll_containers.get_children():
		scroll_container.set_custom_minimum_size(Vector2(0, floori(window_size * 0.3)))
	_on_gameplay_settings_button_pressed()
	setup_setting_signals()

func setup_setting_signals() -> void:
	var fov_slider = get_node("OptionsVBox/MarginContainer2/VBoxContainer/VBoxContainer/ScrollContainers/GameplayScrollContainer/VBoxContainer/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/HSlider")
	fov_slider.value_changed.connect(Settings.fov_slider_value_changed)
	var window_type_optionbutton = get_node("OptionsVBox/MarginContainer2/VBoxContainer/VBoxContainer/ScrollContainers/VideoScrollContainer/VBoxContainer/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/OptionButton")
	window_type_optionbutton.item_selected.connect(Settings.window_type_changed)
	var gamevolume_slider = get_node("OptionsVBox/MarginContainer2/VBoxContainer/VBoxContainer/ScrollContainers/AudioScrollContainer/VBoxContainer/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/HSlider")
	gamevolume_slider.value_changed.connect(Settings.gamevolume_value_changed)

func set_default_visibility() -> void:
	get_node("MenuVBox").visible = true
	get_node("OptionsVBox").visible = false
	get_node("ServerListVBox").visible = false

func open_options_menu() -> void:
	for scroll_container in scroll_containers.get_children():
		scroll_container.scroll_vertical = 0
	get_node("MenuVBox").visible = false
	get_node("OptionsVBox").visible = true
	get_node("ServerListVBox").visible = false

func open_serverlist_menu() -> void:
	print("Opening serverlist menu")
	var lobby_list = MultiplayerManager.get_lobbies_with_friends() 
	var friends_list_node = get_node("ServerListVBox/MarginContainer/VBoxContainer/MarginContainer/ScrollContainer/VBoxContainer")
	# remove all old lobbies
	print("Deleting old lobby buttons")
	for child in friends_list_node.get_children():
			child.queue_free()
	# repopulate the lobby list
	print("Repopulating lobby buttons")
	print("List of lobbies: %s" % str(lobby_list))
	for lobby in lobby_list:
		var data = await MultiplayerManager.get_lobby_info(lobby)
		if data == null:
			continue
		var lobby_id = lobby
		var lobby_name = data["lobby_name"] 
		var _owner_id = int(data["owner_id"])
		var _owner_name = data["owner_name"]
		var owner_avatar = data["owner_avatar"]
		var button = Button.new()
		button.icon = owner_avatar
		button.text = (lobby_name)
		friends_list_node.add_child(button)
		button.pressed.connect(_pressed_join_lobby_button.bind(lobby_id))
	print("Done repopulating lobby buttons")
	get_node("MenuVBox").visible = false
	get_node("OptionsVBox").visible = false
	get_node("ServerListVBox").visible = true

func _pressed_join_lobby_button(lobby_id: int) -> void:
	MultiplayerManager.join_lobby(lobby_id)

func _on_exit_game_button_pressed() -> void:
	get_tree().quit()

func _on_options_button_pressed() -> void:
	open_options_menu()

func _on_back_button_pressed() -> void:
	set_default_visibility()

func _on_gameplay_settings_button_pressed() -> void:
	for scroll_container in scroll_containers.get_children():
		scroll_container.scroll_vertical = 0
		scroll_container.visible = false
	scroll_containers.get_node("GameplayScrollContainer").visible = true
	
func _on_audio_settings_button_pressed() -> void:
	for scroll_container in scroll_containers.get_children():
		scroll_container.scroll_vertical = 0
		scroll_container.visible = false
	scroll_containers.get_node("AudioScrollContainer").visible = true

func _on_video_settings_button_pressed() -> void:
	for scroll_container in scroll_containers.get_children():
		scroll_container.scroll_vertical = 0
		scroll_container.visible = false
	scroll_containers.get_node("VideoScrollContainer").visible = true

func _on_controls_settings_button_pressed() -> void:
	for scroll_container in scroll_containers.get_children():
		scroll_container.scroll_vertical = 0
		scroll_container.visible = false
	scroll_containers.get_node("ControlsScrollContainer").visible = true

func _on_join_lobby_button_pressed() -> void:
	open_serverlist_menu()

func _on_create_lobby_button_pressed() -> void:
	MultiplayerManager.create_lobby()

func begin_loading() -> void:
	get_node("ColorRect").visible = true

func finish_loading() -> void:
	queue_free()
