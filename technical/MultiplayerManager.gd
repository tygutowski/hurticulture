extends Node

const PACKET_READ_LIMIT = 32
const GAME_ID: int = 3281120

enum MessageType {HANDSHAKE, SPAWN_ITEM, SPAWN_ENEMY, USAGE, UPDATE, VOICE}

var lobby_id: int = 0
var steam_id: int = -1
var avatar_list = {}
var peer_container: Node = null
var is_host: bool = false

var item_data: Array = []
var enemy_data: Array = []
var player_data: Array = []

var peer_list: Dictionary = {}

func _init():
	OS.set_environment("SteamAppId", str(GAME_ID))
	OS.set_environment("SteamGameId", str(GAME_ID))

func _ready() -> void:
	if not Global.OFFLINE_MODE:
		initialize_steam()
		steam_id = Steam.getSteamID()
	connect_signals()

func _process(_delta) -> void:
	Steam.run_callbacks()
	if lobby_id > 0:
		peer_list[steam_id].send_packet()
		read_all_p2p_packets()

func connect_signals() -> void:
	# connect all Steam signals to functions
	Steam.p2p_session_request.connect(_on_p2p_session_request)
	Steam.p2p_session_connect_fail.connect(_on_p2p_session_connect_fail)
	Steam.join_requested.connect(_on_lobby_join_requested)
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_data_update.connect(_on_lobby_data_update)
	Steam.persona_state_change.connect(_on_persona_change)
	Steam.avatar_loaded.connect(_on_loaded_avatar)
	Steam.lobby_chat_update.connect(_on_lobby_chat_updated)
	# check cmd line arguments
	check_command_line()

# if there are any errors, close the game
func initialize_steam() -> void:
	var error: Dictionary = Steam.steamInit(true, GAME_ID)
	if error["status"] != 1:
		Debug.debug("Steamworks Error: " + error["verbal"])
		get_tree().quit()
	if not Steam.isSubscribed():
		Debug.debug("User does not own this game")
		get_tree().quit()

func do_stuff_with_packet(data: Dictionary) -> void:
	var keys = data.keys()
	if "type" in keys:
		var type: int = data["type"]
		if type == MessageType.HANDSHAKE:
			# List of all players
			var _player_data: Array = data["player_data"]
			# List of all objects
			var _item_data: Array = data["item_data"]
			# List of all enemies
			var _enemy_data: Array = data["enemy_data"]
			var _has_already_started: bool = data["has_game_started"]
			var _current_power: float = data["current_power"]
			
		elif type == MessageType.SPAWN_ITEM:
			var _item = data["item"]
		elif type == MessageType.SPAWN_ENEMY:
			var node_path = data["node_path"]
			var _enemy = get_node(node_path)
		elif type == MessageType.USAGE:
			var _player_id = data["from"]
			var node_path = data["node_path"]
			var _used_item = get_node(node_path)
		elif type == MessageType.UPDATE:
			var player_id = data["from"]
			var player = peer_container.get_node(player_id)
			if is_instance_valid(player):
				var new_position = data["position"]
				var new_rotation = data["rotation"]
				player.position = new_position
				player.rotation = new_rotation
		elif type == MessageType.VOICE:
			pass

# this is important for joining with shift+tab
func check_command_line() -> void:
	Debug.debug("Checking command line arguments")
	var these_arguments: Array = OS.get_cmdline_args()
	if these_arguments.size() > 0:
		if these_arguments[0] == '+connect_lobby':
			if int(these_arguments[1]) > 0:
				Debug.debug('Commandline lobby ID: %s' % these_arguments[1])
				join_lobby(int(these_arguments[1]))

# when someone attempts to join a lobby
func join_lobby(this_lobby_id: int) -> void:
	Debug.debug("Attempting to join lobby %s" % lobby_id)
	Steam.joinLobby(this_lobby_id)

# load a new world scene and instance all players that are in the lobby
func instance_world(is_sandbox: bool = false) -> Node:
	var world_scene = load("res://environment/World.tscn")
	var world = world_scene.instantiate()
	get_tree().get_root().add_child(world)
	
	if is_sandbox:
		var sandbox_scene: PackedScene = load("res://testing/Sandbox.tscn")
		var sandbox = sandbox_scene.instantiate()
		world.add_child(sandbox)
	
	peer_container = world.get_node("%PeerContainer")
	# load and add players
	for peer_id in peer_list:
		var peer = peer_list[peer_id]
		# if its you, skip
		if peer_is_me(peer):
			continue
		var peer_instance = preload("res://technical/Peer.tscn").instantiate()
		peer_instance.name = str(peer.uid)
		peer_instance.get_node("Label3D").text = peer.username
		peer_container.add_child(peer_instance)
	return world

func peer_is_me(peer: PeerGameState) -> bool:
	return int(peer.uid) == steam_id

# when you join a lobby
func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	# if you successfully join the lobby
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		Debug.debug("Lobby %s joined" % this_lobby_id)
		lobby_id = this_lobby_id
		# update the list of current lobby members
		get_lobby_members()
		# load the world in

	# if you fail joining the lobby
	else:
		var fail_reason: String
		match response:
			Steam.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST: fail_reason = "This lobby no longer exists."
			Steam.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED: fail_reason = "You don't have permission to join this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_FULL: fail_reason = "The lobby is now full."
			Steam.CHAT_ROOM_ENTER_RESPONSE_ERROR: fail_reason = "Uh... something unexpected happened!"
			Steam.CHAT_ROOM_ENTER_RESPONSE_BANNED: fail_reason = "You are banned from this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_LIMITED: fail_reason = "You cannot join due to having a limited account."
			Steam.CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED: fail_reason = "This lobby is locked or disabled."
			Steam.CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN: fail_reason = "This lobby is community locked."
			Steam.CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU: fail_reason = "A user in the lobby has blocked you from joining."
			Steam.CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER: fail_reason = "A user you have blocked is in the lobby."
		Debug.debug("Failed to join this lobby: %s" % fail_reason)

# this is when the peer clicks to join a lobby
func _on_lobby_join_requested(this_lobby_id: int) -> void:
	join_lobby(this_lobby_id)

# this is called all the time to update the lobby info
func get_lobby_members() -> void:
	var number_of_members: int = Steam.getNumLobbyMembers(lobby_id)
	for this_member in range(0, number_of_members):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, this_member)
		
		var _member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
		#var node: Node3D = null
		
		# check if the peer youre parsing doesnt exist yet
		if not peer_list.has(member_steam_id):
			var peer = populate_peer(member_steam_id)
			peer_list[member_steam_id] = peer

func populate_peer(_peer_id: int) -> PeerGameState:
	var peer = PeerGameState.new()
	
	return peer

# this is really updating friend info
func _on_persona_change(this_steam_id: int, _flag: int) -> void:
	if lobby_id > 0:
		Debug.debug("%s's information has changed, updating the lobby list" % this_steam_id)
		get_lobby_members()

func send_p2p_packet(this_target: int, packet_data: Dictionary, type: MessageType) -> void:
	var data: Dictionary = {}
	var send_type: int = -1
	if type == MessageType.HANDSHAKE:
		send_type = Steam.P2P_SEND_RELIABLE
	elif type == MessageType.USAGE:
		send_type = Steam.P2P_SEND_RELIABLE
	elif type == MessageType.SPAWN_ENEMY:
		send_type = Steam.P2P_SEND_RELIABLE
	elif type == MessageType.SPAWN_ITEM:
		send_type = Steam.P2P_SEND_RELIABLE
	elif type == MessageType.UPDATE:
		send_type = Steam.P2P_SEND_UNRELIABLE
	elif type == MessageType.VOICE:
		send_type = Steam.P2P_SEND_UNRELIABLE_NO_DELAY
	assert(send_type != -1)
	data["type"] = type
	var channel: int = 0
	
	var this_data: PackedByteArray
	var compressed_data: PackedByteArray = var_to_bytes(packet_data).compress(FileAccess.COMPRESSION_GZIP)
	this_data.append_array(compressed_data)
	
	if this_target == 0:

		for peer_id in peer_list:
			var peer = peer_list[peer_id]
			if not peer_is_me(peer):
				Steam.sendP2PPacket(peer.uid, this_data, send_type, channel)
	else:
		Steam.sendP2PPacket(this_target, this_data, send_type, channel)

func initialize_new_peer(player_id: int) -> void:
	Debug.debug("Sending P2P handshake to new player")
	var packet = {
		"has_game_started" : PowerManager.has_game_started,
		"current_power" : PowerManager.current_power,
		"item_data" : item_data,
		"enemy_data" : enemy_data,
		"player_data" : player_data
	}
	send_p2p_packet(player_id, packet, MessageType.HANDSHAKE)

# when someone joins the lobby youre in lobby
func add_to_lobby(player_id: int):
	Debug.debug("A player joined! Adding them to lobby")
	var peer_scene = load("res://peer.tscn")
	var peer = peer_scene.instantiate()
	peer.name = str(player_id)
	var username = Steam.getFriendPersonaName(player_id)
	peer.get_node("Label3D").text = username
	peer_container.add_child(peer)
	if is_host:
		initialize_new_peer(player_id)

#when the lobby is updated
func _on_lobby_chat_updated(_this_lobby_id: int, change_id: int, _making_change_id: int, chat_state: int) -> void:
	var changer_name: String = Steam.getFriendPersonaName(change_id)
	# If a player has joined the lobby
	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		Debug.debug("%s has joined the lobby." % changer_name)
		add_to_lobby(_making_change_id)
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
		Debug.debug("%s has left the lobby." % changer_name)
		peer_container.get_node(str(_making_change_id)).queue_free()
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_KICKED:
		Debug.debug("%s has been kicked from the lobby." % changer_name)
		peer_container.get_node(str(_making_change_id)).queue_free()
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_BANNED:
		Debug.debug("%s has been banned from the lobby." % changer_name)
		peer_container.get_node(str(_making_change_id)).queue_free()
	else:
		Debug.debug("%s did something." % changer_name)
	get_lobby_members()

func leave_lobby() -> void:
	# If in a lobby, leave it
	if lobby_id != 0:
		# Send leave request to Steam
		Steam.leaveLobby(lobby_id)
		# Wipe the Steam lobby ID then display the default lobby ID and player list title
		lobby_id = 0
		# Close session with all users
		for peer_id in peer_list:
			var peer = peer_list[peer_id]
			# Make sure this isn't your Steam ID
			if not peer_is_me(peer):
				# Close the P2P session
				Steam.closeP2PSessionWithUser(peer.uid)
		# Clear the local lobby list
		peer_list.clear()

func create_lobby() -> void:
	if lobby_id == 0:
		Debug.debug("Creating lobby")
		Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, 3)
		is_host = true
	else:
		Debug.debug("ERROR: Cannot create a lobby, as you are already in a lobby.")

func _on_lobby_created(error: int, this_lobby_id: int) -> void:
	if error == 1:
		lobby_id = this_lobby_id
		Debug.debug("Created a lobby: %s" % lobby_id)
		Steam.setLobbyJoinable(lobby_id, true)
		Steam.setLobbyData(lobby_id, "owner_id", str(steam_id))
		Steam.setLobbyData(lobby_id, "owner_name", Steam.getPersonaName())
		Steam.setLobbyData(lobby_id, "lobby_name", Steam.getPersonaName() + "'s Lobby")
		# allow p2p connections to fallback to being relayed
		# through steam if necessary
		var set_relay: bool = Steam.allowP2PPacketRelay(true)
		Debug.debug("Allowing Steam to be relay backup: %s" % set_relay)
	else:
		Debug.debug("Failure creating lobby: %s" % error)

func read_all_p2p_packets(read_count: int = 0) -> void:
	if read_count >= PACKET_READ_LIMIT:
		return
	if Steam.getAvailableP2PPacketSize(0) > 0:
		read_p2p_packet()
		read_all_p2p_packets(read_count + 1)

func _on_p2p_session_request(remote_id: int) -> void:
	var requester: String = Steam.getFriendPersonaName(remote_id)
	Debug.debug("%s is requesting a P2P session" % requester)
	Steam.acceptP2PSessionWithUser(remote_id)

func read_p2p_packet() -> void:
	var packet_size: int = Steam.getAvailableP2PPacketSize(0)
	if packet_size > 0:
		var this_packet: Dictionary = Steam.readP2PPacket(packet_size, 0)
		if this_packet.is_empty() or this_packet == null:
			Debug.debug("WARNING: read an empty packet with non-zero size!")
		
		# get remote user ID
		#var packet_sender: int = this_packet['remote_steam_id']
		var packet_code: PackedByteArray = this_packet['data']
		var readable_data: Dictionary = bytes_to_var(packet_code.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP))
		
		do_stuff_with_packet(readable_data)

func _on_p2p_session_connect_fail(this_steam_id: int, session_error: int) -> void:
	# If no error was given
	if session_error == 0:
		Debug.debug("WARNING: Session failure with %s: no error given" % this_steam_id)
	# Else if target user was not running the same game
	elif session_error == 1:
		Debug.debug("WARNING: Session failure with %s: target user not running the same game" % this_steam_id)
	# Else if local user doesn't own app / game
	elif session_error == 2:
		Debug.debug("WARNING: Session failure with %s: local user doesn't own app / game" % this_steam_id)
	# Else if target user isn't connected to Steam
	elif session_error == 3:
		Debug.debug("WARNING: Session failure with %s: target user isn't connected to Steam" % this_steam_id)
	# Else if connection timed out
	elif session_error == 4:
		Debug.debug("WARNING: Session failure with %s: connection timed out" % this_steam_id)
	# Else if unused
	elif session_error == 5:
		Debug.debug("WARNING: Session failure with %s: unused" % this_steam_id)
	# Else no known error
	else:
		Debug.debug("WARNING: Session failure with %s: unknown error %s" % [this_steam_id, session_error])

func get_lobby_info(this_lobby_id: int):
	Debug.debug("Getting info for lobby %s" % str(this_lobby_id))
	var data: Dictionary
	var error = Steam.requestLobbyData(this_lobby_id)
	# wait for the lobby data to update
	await Steam.lobby_data_update
	if not error:
		Debug.debug("WARNING: Failure to get lobby data for lobby %s" % str(this_lobby_id))
		return null

	data["owner_id"] = Steam.getLobbyData(this_lobby_id, "owner_id")
	data["owner_name"] = Steam.getLobbyData(this_lobby_id, "owner_name")
	# Make sure you finish loading the player's avatar
	Steam.getPlayerAvatar(3, int(data["owner_id"]))
	await Steam.avatar_loaded
	data["owner_avatar"] = avatar_list[int(data["owner_id"])]
	data["lobby_name"] = Steam.getLobbyData(this_lobby_id, "lobby_name")
	return data

func get_lobbies_with_friends() -> Dictionary:
	var results: Dictionary = {}
	# find all friends
	Debug.debug("Finding all friends online")
	for i in range(0, Steam.getFriendCount(Steam.FRIEND_FLAG_ALL)):
		var this_steam_id: int = Steam.getFriendByIndex(i, Steam.FRIEND_FLAG_IMMEDIATE)
		var game_info: Dictionary = Steam.getFriendGamePlayed(this_steam_id)
		
		# that are in a game
		if game_info.is_empty():
			# if this friend isnt playing a game
			continue
		else:
			# get info about what your friends are doing
			var app_id: int = game_info['id']
			var lobby: int = game_info['lobby']
			
			# if your friend isn't playing your game
			if app_id != Steam.getAppID():
				continue
				#pass
			
			# check to see if this lobby already exists
			# if not, initialize it
			if not results.has(lobby):
				results[lobby] = []
			# add this player to the lobby list
			results[lobby].append(this_steam_id)
			
	return results

func _on_lobby_data_update(_success: int, _lobby_id: int, _member_id: int) -> void:
	Debug.debug("Lobby data updated")

func _on_loaded_avatar(user_id: int, avatar_size: int, avatar_buffer: PackedByteArray) -> void:
	var avatar_image: Image = Image.create_from_data(avatar_size, avatar_size, false, Image.FORMAT_RGBA8, avatar_buffer)
	if avatar_size > 128:
		avatar_image.resize(128, 128, Image.INTERPOLATE_LANCZOS)
	var avatar_texture: ImageTexture = ImageTexture.create_from_image(avatar_image)
	avatar_list[user_id] = avatar_texture
