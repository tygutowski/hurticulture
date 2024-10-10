extends Interactable

@export var electronics : Array[Node3D] = []

func flip_switch():
	get_node("SwitchOnStream").play()
	for electronic in electronics:
		electronic.interact()

func interact():
	var packet = {
		"node_path" = get_path()
	}
	MultiplayerManager.send_p2p_packet(0, packet, MultiplayerManager.MessageType.USAGE)
	flip_switch()
