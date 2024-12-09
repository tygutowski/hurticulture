extends Resource
class_name Peer

var id: int = 12345
var username: String = 'username'
var position: Vector3 = Vector3.ZERO
var rotation: Vector3 = Vector3.ZERO
var node: Node3D = null

enum ConnectionStatuses {DISCONNECTED, CONNECTED, LOBBY}
var connection_status: int = ConnectionStatuses.DISCONNECTED
var is_host: bool = false

var is_alive: bool = true
var max_health: float = 100.0
var health: float = max_health
var held_item: Node3D = null

func send_packet() -> void:
	var packet: Dictionary = {}
	packet['from'] = id
	packet['position'] = position
	packet['rotation'] = rotation
	MultiplayerManager.send_p2p_packet(0, packet, MultiplayerManager.MessageType.UPDATE)
