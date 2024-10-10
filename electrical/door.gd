extends Electrical

var off_position: Vector3 = Vector3(0, 3.75, 0)
var on_position: Vector3 = Vector3.ZERO
var movement_time: float = 2.42
var animating : bool = false
var tween : Tween
# we get these from button.gd

func _ready() -> void:
	if state == ElectricalState.OFF:
		turn_off(false, false)
	elif state == ElectricalState.ON:
		turn_on(false, false)

func interact() -> void:
	var data: Dictionary = {}
	MultiplayerManager.send_p2p_packet(0, data, MultiplayerManager.PacketTypes.TCP)
	if PowerManager.power_out:
		return
	if tween and tween.is_running():
		return
	if state == ElectricalState.OFF:
		turn_on(true, false)
	elif state == ElectricalState.ON:
		turn_off(true, false)

# opens all doors when power goes out
func power_outage() -> void:
	# stop animations
	if tween:
		tween.kill()
	turn_off(true, true)

# we dont reshut the doors if power is returned
func power_return() -> void:
	pass

# Opens door
func turn_off(animate : bool, _power_outage : bool) -> void:
	if _power_outage:
		if state == ElectricalState.ON:
			state = ElectricalState.OFF
	else:
		state = ElectricalState.OFF
	if state == ElectricalState.OFF:
		if animate:
			$AirReleasePlayer.play()
			animating = true
			tween = create_tween()
			tween.tween_property(get_node("Door"), "position:y", off_position.y, movement_time)
		#await tween.finished
			animating = false
		else:
			get_node("Door").position.y = off_position.y

# Closes door
func turn_on(animate: bool, _power_return : bool) -> void:
	state = ElectricalState.ON
	if animate:
		$HydraulicPlayer.play()
		animating = true
		tween = create_tween()
		tween.tween_property(get_node("Door"), "position:y", on_position.y, movement_time)
		await tween.finished
		animating = false
		await $HydraulicPlayer.finished
		$ImpactPlayer.play()
	else:

		get_node("Door").position.y = on_position.y
	state = ElectricalState.ON
