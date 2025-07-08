extends Node

var resolutions = [
	Vector2(1920, 1080),
	Vector2(640, 480)
	]
var resolution

var window_modes = [
	DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN, 
	DisplayServer.WINDOW_MODE_FULLSCREEN,
	DisplayServer.WINDOW_MODE_WINDOWED
	]
var window_mode

var gamma : int = -1
var base_fov : int = -1 # without any manipulations from charging items or running
var fov : float = base_fov # with manipulations
var game_volume : int = -1
var voice_volume : int = -1
var microphone_volume : int = -1
var microphone_threshold : int = -1

const default_resolution : int = 1
const default_windowmode : int = 0
const default_gamma : int = 50
const default_fov : int = 75
const default_game_volume : int = 50
const default_voice_volume : int = 50
const default_microphone_volume : int = 50
const default_microphone_threshold : int = 50

func _ready():
	set_resolution(default_resolution)
	set_windowmode(default_windowmode)
	set_gamma(default_gamma)
	set_fov(default_fov)
	set_game_volume(default_game_volume)
	set_voice_volume(default_voice_volume)
	set_microphone_volume(default_microphone_volume)
	set_microphone_threshold(default_microphone_threshold)

func set_gamma(_gamma):
	gamma = _gamma

func set_fov(_base_fov):
	base_fov = _base_fov

func set_game_volume(_volume):
	game_volume = _volume

func set_voice_volume(_volume):
	voice_volume = _volume

func set_microphone_volume(_volume):
	microphone_volume = _volume

func set_microphone_threshold(_threshold):
	microphone_threshold = _threshold

func set_resolution(_resolution):
	resolution = _resolution
	DisplayServer.window_set_size(resolutions[resolution])
	DisplayServer.window_set_position(get_viewport().size/2)

func window_type_changed(index : int) -> void:
	set_windowmode(index)

func set_windowmode(_window_mode):
	window_mode = _window_mode
	DisplayServer.window_set_mode(window_modes[window_mode])

func fov_slider_value_changed(value : int):
	base_fov = value

func gamevolume_value_changed(value : int):
	game_volume = value
