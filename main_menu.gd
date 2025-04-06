extends Control

signal lobby_created

@onready var menu = %Interface

@onready var inputblock = %InputBlock

@onready var miniscreen = %MiniScreen
@onready var miniscreenlabel = %MiniScreenLabel
@onready var miniscreenscreen = %MiniScreenScreen
@onready var title = %Title
@onready var main_menu = %MainMenu

@onready var owner_lobby = %OwnerLobby
@onready var peer_lobby = %PeerLobby

@onready var settings = %Settings
@onready var worldloading = %WorldLoading

@onready var mainmenu_grid = %MainMenuGrid
@onready var settings_grid = %SettingsGrid
@onready var lobby_grid = %LobbyGrid

@onready var tygutowski = %TygutowskiSplash

@onready var miniscreen_gameplay = get_node("%gameplay")
@onready var miniscreen_sfx = get_node("%audio")
@onready var miniscreen_video = get_node("%video")

@onready var hover_button_noise: AudioStreamWAV = preload("res://GUI/accept_button_sound.wav")
@onready var click_button_noise: AudioStreamWAV = preload("res://GUI/hover_button_sound.wav")

@onready var ty_sound: AudioStreamWAV = preload("res://GUI/ty_sound.wav")
@onready var gu_sound: AudioStreamWAV = preload("res://GUI/gu_sound.wav")
@onready var tow_sound: AudioStreamWAV = preload("res://GUI/tow_sound.wav")
@onready var ski_sound: AudioStreamWAV = preload("res://GUI/ski_sound.wav")
@onready var goodbye_sound: AudioStreamWAV = preload("res://GUI/goodbye_sound.wav")

@onready var audio_stream_player_beep: AudioStreamPlayer = get_node("AudioStreamPlayerBeep")
@onready var audio_stream_player_hover: AudioStreamPlayer = get_node("AudioStreamPlayerHover")
@onready var audio_stream_player_voice: AudioStreamPlayer = get_node("AudioStreamPlayerVoice")

var playing_bootup = false

func play_bootup() -> void:
	inputblock.visible = true
	tygutowski.visible = true
	menu.visible = false
	playing_bootup = true
	tygutowski.text = '[center][color=b2b2a2][/color][color=243636]tygutowski[/color][/center]'
	if playing_bootup:
		tygutowski.text = '[center][color=b2b2a2]ty[/color][color=243636]gutowski[/color][/center]'
		audio_stream_player_voice.set_stream(ty_sound)
		audio_stream_player_voice.play()
		await audio_stream_player_voice.finished
	if playing_bootup:
		tygutowski.text = '[center][color=b2b2a2]tygu[/color][color=243636]towski[/color][/center]'
		audio_stream_player_voice.set_stream(gu_sound)
		audio_stream_player_voice.play()
		await audio_stream_player_voice.finished
	if playing_bootup:
		tygutowski.text = '[center][color=b2b2a2]tygutow[/color][color=243636]ski[/color][/center]'
		audio_stream_player_voice.set_stream(tow_sound)
		audio_stream_player_voice.play()
		await audio_stream_player_voice.finished
	if playing_bootup:
		tygutowski.text = '[center][color=b2b2a2]tygutowski[/color][color=243636][/color][/center]'
		audio_stream_player_voice.set_stream(ski_sound)
		audio_stream_player_voice.play()
		await audio_stream_player_voice.finished
	end_bootup()

func end_bootup() -> void:
	tygutowski.visible = false
	inputblock.visible = false
	menu.visible = true
	playing_bootup = false
	audio_stream_player_voice.stop()

func open_miniscreen() -> void:
	miniscreen.visible = true

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		end_bootup()

func _ready() -> void:
	miniscreen.visible = false
	toggle_visibility(main_menu)
	var window_size = get_viewport().size.y
	for scroll_container in settings.get_children():
		scroll_container.set_custom_minimum_size(Vector2(0, floori(window_size * 0.3)))
	setup_setting_signals()
	play_bootup()

func _set_generation_info(info: String) -> void:
	Debug.debug("INFO: " + info)
	var label = worldloading.get_node("MarginContainer/GeneratingBox/Label")
	label.text = info

func _generation_finished() -> void:
	Debug.debug("GENERATION FINISHED!")
	visible = false

func setup_setting_signals() -> void:
	%FovSlider.value_changed.connect(Settings.fov_slider_value_changed)
	%WindowMode.item_selected.connect(Settings.window_type_changed)
	%MasterVolumeSlider.value_changed.connect(Settings.gamevolume_value_changed)

func _on_options_button_pressed() -> void:
	open_options_menu()

func open_options_menu() -> void:
	open_miniscreen()
	set_grid_focus(settings_grid)
	set_settings_focus(miniscreen_gameplay)
	toggle_visibility(settings)

func change_settings_tab(node) -> void:
	node.scroll_vertical = 0

func open_serverlist_menu() -> void:
	Debug.debug("Opening serverlist menu")
	var lobby_list = MultiplayerManager.get_lobbies_with_friends() 
	if lobby_list.is_empty():
		return
	# remove all old lobbies
	Debug.debug("Deleting old lobby buttons")
	for lobby in lobby_grid.get_children():
			lobby.queue_free()
	# repopulate the lobby list
	Debug.debug("Repopulating lobby buttons")
	Debug.debug("List of lobbies: %s" % str(lobby_list))
	for lobby in lobby_list:
		var data = await MultiplayerManager.get_lobby_info(lobby)
		
		if data == null:
			continue
		var lobby_id = lobby
		var _lobby_name = data["lobby_name"] 
		var _owner_id = int(data["owner_id"])
		var _owner_name = data["owner_name"]
		var _owner_avatar = data["owner_avatar"]
		var lobby_data_node = preload("res://GUI/Lobby/in_lobby_player_data.tscn")
		var lobby_data = lobby_data_node.instantiate()
		lobby_grid.add_child(lobby_data)
		lobby_data.pressed.connect(_pressed_join_lobby_button.bind(lobby_id))
	Debug.debug("Done repopulating lobby buttons")
	open_miniscreen()
	set_grid_focus(lobby_grid)

func _pressed_join_lobby_button(lobby_id: int) -> void:
	join_lobby(lobby_id)

func join_lobby(lobby_id: int) -> void:
	MultiplayerManager.join_lobby(lobby_id)


func _on_exit_game_button_pressed() -> void:
	close_game()

func close_game() -> void:
	inputblock.visible = true
	audio_stream_player_voice.set_stream(goodbye_sound)
	audio_stream_player_voice.play()
	await audio_stream_player_voice.finished
	get_tree().quit()

func toggle_visibility(target_node: Node) -> void:
	# Hide all siblings of the target node
	for node in target_node.get_parent().get_children():
		node.visible = false
	# Show only the target node
	title.visible = true
	target_node.visible = true

func _on_join_lobby_button_pressed() -> void:
	open_serverlist_menu()

func _on_create_lobby_button_pressed() -> void:
	open_miniscreen()
	miniscreenlabel.text = ' host lobby'
	set_miniscreen_focus(owner_lobby)
	MultiplayerManager.create_lobby()
	lobby_created.emit()

func finish_loading() -> void:
	visible = false

func _mouse_hovered() -> void:
	play_hovering_noise()

func _click_button() -> void:
	play_clicking_noise()

func play_hovering_noise() -> void:
	audio_stream_player_hover.play()

func play_clicking_noise() -> void:
	audio_stream_player_beep.play()

func play_clicking_noise2() -> void:
	audio_stream_player_beep.play()

func _close_miniscreen() -> void:
	close_miniscreen()

func close_miniscreen() -> void:
	set_grid_focus(mainmenu_grid)
	miniscreen.visible = false

func set_grid_focus(node) -> void:
	var parent = node.get_parent()
	for child in parent.get_children():
		child.visible = false
	node.visible = true

func set_settings_focus(node) -> void:
	for child in settings.get_children():
		child.visible = false
	miniscreenlabel.text = ' ' + node.name
	node.visible = true

func _settings_gameplay_clicked() -> void:
	set_settings_focus(miniscreen_gameplay)
	
func _settings_audio_clicked() -> void:
	set_settings_focus(miniscreen_sfx)
	
func _settings_video_clicked() -> void:
	set_settings_focus(miniscreen_video)

func set_miniscreen_focus(node) -> void:
	for child in miniscreenscreen.get_children():
		child.visible = false
	node.visible = true

func _generate_world() -> void:
	set_miniscreen_focus(worldloading)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var world: Node = MultiplayerManager.instance_world()
	var world_generator: Node = world.get_node("WorldGenerator")
	world_generator.generation_stage_changed.connect(_set_generation_info)
	world_generator.generation_finished.connect(_generation_finished)
	world_generator.generate_world(false)


func _on_slider_value_changed(_value: float) -> void:
	play_hovering_noise()

func update_fov(value: float) -> void:
	%FovLabel.text = str(value)

func update_mastervolume(value: float) -> void:
	%MasterVolumeLabel.text = str(value)
	
func update_gamevolume(value: float) -> void:
	%GameVolumeLabel.text = str(value)
	
func update_voicevolume(value: float) -> void:
	%VoiceVolumeLabel.text = str(value)
	
func update_micintensity(value: float) -> void:
	%MicrophoneIntensityLabel.text = str(value)
	
func update_micthreshold(value: float) -> void:
	%MicrophoneThresholdLabel.text = str(value)

func _load_sandbox_world() -> void:
	set_miniscreen_focus(worldloading)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var world: Node = MultiplayerManager.instance_world()
	var world_generator: Node = world.get_node("WorldGenerator")
	world_generator.generation_stage_changed.connect(_set_generation_info)
	world_generator.generation_finished.connect(_generation_finished)
	world_generator.generate_world(true)
	
