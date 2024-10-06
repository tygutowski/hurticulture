extends Interactable

# node that we will be interacting with
@export var electronics : Array[Node3D] = []

func locally_interact():
	for electronic in electronics:
		electronic.interact()

func interact():
	var packet = {
		"type" = MultiplayerManager.MessageType.INTERACTION,
		"node_path" = get_path()
	}
	MultiplayerManager.send_p2p_packet(0, packet)
	locally_interact()
