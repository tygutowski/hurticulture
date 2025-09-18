extends Electrical

@export var default_light_range = 12

var light_timer: float = 1.0
var time_since_last_turned_on : float = 999

@onready var off_texture = load("res://environment/materials/florescentlight_off.tres")
@onready var on_texture = load("res://environment/materials/florescentlight_on.tres")
@onready var clinking_audio_list = [
	load("res://audio/fluorescent-clinking1.wav"),
	load("res://audio/fluorescent-clinking2.wav")
]

func _ready() -> void:
	if state == ElectricalState.OFF:
		turn_off(false, false)
	elif state == ElectricalState.ON:
		turn_on(false, false)

func interact() -> void:
	if PowerManager.power_out:
		return
	if state == ElectricalState.OFF:
		turn_on(true, false)
	elif state == ElectricalState.ON:
		turn_off(true, false)

func power_outage() -> void:
	turn_off(true, true)

func power_return() -> void:
	turn_on(true, false)

# Turns off the light
func turn_off(_animate : bool, _power_outage : bool) -> void:
	if _power_outage:
		if state == ElectricalState.ON:
			state = ElectricalState.STANDBY
	else:
		state = ElectricalState.OFF

	if state == ElectricalState.OFF or ElectricalState.STANDBY:
		get_node('OmniLight3D').omni_range = 0
		get_node('SwitchAudio').play()
		get_node('SwitchAudio').pitch_scale = .75
		get_node('Tube1Mesh').set_surface_override_material(0, off_texture)
		get_node('Tube2Mesh').set_surface_override_material(0, off_texture)
		get_node('BuzzingAudio').stop()

# Turns on the light
func turn_on(animate : bool, _power_return : bool) -> void:
	if _power_return:
		if state == ElectricalState.STANDBY:
			state = ElectricalState.ON
	else:
		state = ElectricalState.ON
	if state == ElectricalState.ON:
		if animate:
			get_node('OnTimer').start(light_timer)
			await get_node('OnTimer').timeout
		get_node('OmniLight3D').omni_range = default_light_range
		get_node('Tube1Mesh').set_surface_override_material(0, on_texture)
		get_node('Tube2Mesh').set_surface_override_material(0, on_texture)
		if animate:
			get_node('SwitchAudio').play()
			get_node('SwitchAudio').pitch_scale = 1
			await get_node('SwitchAudio').finished
			get_node('ClinkingTimer').start(randf_range(0, 1))
			await get_node('ClinkingTimer').timeout
			get_node('ClinkingAudio').stream = clinking_audio_list.pick_random()
			get_node('ClinkingAudio').pitch_scale = randf_range(0.9, 1.1)
			var clinking_chance = randf_range(0,1)
			if clinking_chance <= max(0.2, max(time_since_last_turned_on/600, 1)):
				get_node('ClinkingAudio').play()
		get_node('BuzzingAudio').play()

func add_power_drain():
	PowerManager.add_power_drain(power_consumption)

func remove_power_drain():
	PowerManager.remove_power_drain(power_consumption)

func receive_power() -> void:
	get_parent().power_return()

func lose_power() -> void:
	get_parent().power_outage()

# Called to toggle the state of the object (on/off/standby)
func set_state(new_state: ElectricalState) -> void:
	state = new_state
