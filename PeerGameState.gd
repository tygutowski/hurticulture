extends Resource
class_name PeerGameState

# This is local for each player, when saving, the host grabs all local gamestates and combines them into one

# transform
var position: Vector3 = Vector3.ZERO
var rotation: Vector3 = Vector3.ZERO

# connection
var uid: int = 0
var username: String = ""
var session_id: int = 0
var is_host: bool = false

# health and statuses
var max_health: float = 100.0
var current_health: float = 0
var is_alive: bool = true
var status_effects: Array[Status] = []

# inventory
var held_item: Node3D = null
var inventory: Array[Array] = []

# player cosmetic data
var head_type = Global.PlayerHeads.CYBERPUNK
var colors: Dictionary[int, Color] = {
	Global.PlayerBodyPart.HYDRAULICS:  Color(1.0,1.0,1.0),
	Global.PlayerBodyPart.CHEST:       Color(1.0,1.0,1.0),
	Global.PlayerBodyPart.PELVIS:      Color(1.0,1.0,1.0),
	Global.PlayerBodyPart.LEGS:        Color(1.0,1.0,1.0),
	Global.PlayerBodyPart.FEET:        Color(1.0,1.0,1.0),
	Global.PlayerBodyPart.ARMS:        Color(1.0,1.0,1.0),
	Global.PlayerBodyPart.HEAD:        Color(1.0,1.0,1.0),
	Global.PlayerBodyPart.HEAD_ACCENT: Color(1.0,1.0,1.0),
	Global.PlayerBodyPart.EYES:        Color(1.0,1.0,1.0)
}

func send_packet() -> void:
	var packet: Dictionary = {}
	packet['from'] = uid
	packet['position'] = position
	packet['rotation'] = rotation
	MultiplayerManager.send_p2p_packet(0, packet, MultiplayerManager.MessageType.UPDATE)
