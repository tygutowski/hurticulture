extends Interactable

# node that we will be interacting with
@export var electronics : Array[Node3D] = []

func push_button():
	for electronic in electronics:
		electronic.interact()

func interact():
	var packet = {
		"node_path" = get_path()
	}
	MultiplayerManager.send_p2p_packet(0, packet, MultiplayerManager.USAGE)
	push_button()
