extends Interactable

@export var electronics : Array[Node3D] = []

func locally_interact():
	get_node("SwitchOnStream").play()
	for electronic in electronics:
		electronic.interact()

func interact():
	var packet = {
		"type" = MultiplayerManager.MessageType.INTERACTION,
		"node_id" = get_instance_id()
	}
	MultiplayerManager.send_p2p_packet(0, packet)
	locally_interact()
