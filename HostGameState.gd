extends Resource
class_name HostGameState

# This is a collection of PeerGameStates that the host combines to load at a later time.
# The data is ONLY stored on the host's computer

var player_gamestates: Array[PeerGameState] = []

# data that the host stores locally
# (essentially server data)
var deployed_items: Array[Deployable] = []
var dropped_items: Array[Item]
var plants: Array[Plant]
var time_elapsed: float = 0

func get_peer_gamestates() -> Array[PeerGameState]:
	var peer_gamestates: Array[PeerGameState] = []
	for peer in MultiplayerManager.peer_list:
		var peer_gamestate = peer.gamestate
		peer_gamestates.append(peer_gamestate)
	return peer_gamestates
