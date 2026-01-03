extends Interactable

# node that we will be interacting with
@export var electronics : Array[Electrical] = []

var on: bool = false

func flip_switch():
	on = not on
	if on:
		$AnimationPlayer.play("SwitchOn")
	else:
		$AnimationPlayer.play("SwitchOff")
	for electronic in electronics:
		electronic.interact()

func interact():
	if $AnimationPlayer.is_playing():
		return
	flip_switch()
	var packet = {
		"node_path" = get_path()
	}
	MultiplayerManager.send_p2p_packet(0, packet, MultiplayerManager.MessageType.USAGE)
