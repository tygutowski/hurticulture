extends Node

var lobby_id: int = 0
var lobby_members: Array[Dictionary] = []
var steam_id: int = -1
var steam_username: String = ''
var nickname: String = 'player'
var avatar_list = {}
var peers: Node3D = null
const PACKET_READ_LIMIT = 32
var is_host: bool = false

enum MessageType {HANDSHAKE, PLAYER_UPDATE}

func _init():
	OS.set_environment("SteamAppId", str(480))
	OS.set_environment("SteamGameId", str(480))

func _ready() -> void:
	initialize_steam()
	connect_signals()
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()

func do_stuff_with_packet(data: Dictionary) -> void:
	# if youre sending yourself shit
	if data["from"] == steam_id:
		return
	if data["type"] == MessageType.PLAYER_UPDATE:
		var node_name = data["from"]
		var node = peers.get_node_or_null(str(node_name))
		var transform = data["pos"]
		# checking to be safe lol
		if node != null:
			node.transform = transform
	# if you're a peer, update to be equal to the host
	elif data["type"] == MessageType.HANDSHAKE:
		print("Received handshake")
		if not is_host:
			print("Setting the power")
			var current_power = int(data["pow"])
			PowerManager.current_power = current_power


func initialize_steam() -> void:
	var error: Dictionary = Steam.steamInit(true, 480)
	if error["status"] != 1:
		print("Steamworks Error: " + error["verbal"])
		get_tree().quit()
	if not Steam.isSubscribed():
		print("User does not own this game")
		get_tree().quit()

func connect_signals() -> void:
	print("Connecting signals")
	Steam.p2p_session_request.connect(_on_p2p_session_request)
	Steam.p2p_session_connect_fail.connect(_on_p2p_session_connect_fail)
	Steam.join_requested.connect(_on_lobby_join_requested)
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_data_update.connect(_on_lobby_data_update)
	Steam.persona_state_change.connect(_on_persona_change)
	Steam.avatar_loaded.connect(_on_loaded_avatar)
	Steam.lobby_chat_update.connect(_on_lobby_chat_updated)
	check_command_line() # check cmd line arguments

func _process(_delta) -> void:
	Steam.run_callbacks()
	if lobby_id > 0:
		read_all_p2p_packets()

# this is important for joining with shift+tab
func check_command_line() -> void:
	print("Checking command line arguments")
	var these_arguments: Array = OS.get_cmdline_args()
	if these_arguments.size() > 0:
		if these_arguments[0] == '+connect_lobby':
			if int(these_arguments[1]) > 0:
				print('Commandline lobby ID: %s' % these_arguments[1])
				join_lobby(int(these_arguments[1]))

func join_lobby(this_lobby_id: int) -> void:
	print("Attempting to join lobby %s" % lobby_id)
	lobby_members.clear()
	Steam.joinLobby(this_lobby_id)

func load_world() -> void:
	# load the world scene
	var world_scene = load("res://environment/world.tscn")
	var world = world_scene.instantiate()
	peers = world.get_node("Peers")
	# load and add players
	for i in range(len(lobby_members)):
		# if its you, skip
		if lobby_members[i]["steam_id"] == steam_id:
			continue
		var peer_scene = load("res://peer.tscn")
		var peer = peer_scene.instantiate()
		peer.name = str(lobby_members[i]["steam_id"])
		var username = str(lobby_members[i]["steam_name"])
		peer.get_node("Label3D").text = username
		peers.add_child(peer)
	get_tree().get_root().add_child(world)

# when you join a lobby
func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		print("Lobby %s joined" % this_lobby_id)
		lobby_id = this_lobby_id
		var main_menu = get_tree().current_scene
		main_menu.begin_loading()
		# update the list of current lobby members
		get_lobby_members()
		# load the world in
		load_world()
		# get world data
		make_p2p_handshake()
		main_menu.finish_loading()
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
		print("Failed to join this lobby: %s" % fail_reason)
		# go back to the menu

func _on_lobby_join_requested(this_lobby_id: int) -> void:
	join_lobby(this_lobby_id)

func get_lobby_members() -> void:
	lobby_members.clear()
	var number_of_members: int = Steam.getNumLobbyMembers(lobby_id)
	for this_member in range(0, number_of_members):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, this_member)
		
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
		var node: Node3D = null
		
		if peers != null:
			node = peers.get_node_or_null(str(member_steam_id))
		lobby_members.append({
			"steam_id"   : member_steam_id,
			"steam_name" : member_steam_name,
			"node"       : node
			})

# this is really updating friend info
func _on_persona_change(this_steam_id: int, _flag: int) -> void:
	if lobby_id > 0:
		print("%s's information has changed, updating the lobby list" % this_steam_id)
		get_lobby_members()

func send_p2p_packet(this_target: int, packet_data: Dictionary) -> void:
	var send_type: int = Steam.P2P_SEND_RELIABLE
	var channel: int = 0
	
	var this_data: PackedByteArray
	var compressed_data: PackedByteArray = var_to_bytes(packet_data).compress(FileAccess.COMPRESSION_GZIP)
	this_data.append_array(compressed_data)
	
	if this_target == 0:
		if lobby_members.size():
			# loop through everyone that isnt you
			for this_member in lobby_members:
				if this_member['steam_id'] != steam_id:
					Steam.sendP2PPacket(this_member['steam_id'], this_data, send_type, channel)
	else:
		Steam.sendP2PPacket(this_target, this_data, send_type, channel)

func get_steam_id() -> int:
	return steam_id

func make_p2p_handshake() -> void:
	print("Sending P2P handshake to the lobby")
	send_p2p_packet(0, {
		"type" : MessageType.HANDSHAKE,
		"from" : steam_id,
		# power
		"pow" : PowerManager.current_power,
		# upgrades
		"ups" : []
	})

func add_to_lobby(player_id: int):
	print("A player joined! Adding them to lobby")
	var peer_scene = load("res://peer.tscn")
	var peer = peer_scene.instantiate()
	peer.name = str(player_id)
	var username = Steam.getFriendPersonaName(player_id)
	peer.get_node("Label3D").text = username
	peers.add_child(peer)

#when the lobby is updated
func _on_lobby_chat_updated(_this_lobby_id: int, change_id: int, _making_change_id: int, chat_state: int) -> void:
	var changer_name: String = Steam.getFriendPersonaName(change_id)
	# If a player has joined the lobby
	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		print("%s has joined the lobby." % changer_name)
		add_to_lobby(_making_change_id)
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
		print("%s has left the lobby." % changer_name)
		peers.get_node(str(_making_change_id)).queue_free()
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_KICKED:
		print("%s has been kicked from the lobby." % changer_name)
		peers.get_node(str(_making_change_id)).queue_free()
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_BANNED:
		print("%s has been banned from the lobby." % changer_name)
		peers.get_node(str(_making_change_id)).queue_free()
	else:
		print("%s did something." % changer_name)
	get_lobby_members()

func leave_lobby() -> void:
	# If in a lobby, leave it
	if lobby_id != 0:
		# Send leave request to Steam
		Steam.leaveLobby(lobby_id)
		# Wipe the Steam lobby ID then display the default lobby ID and player list title
		lobby_id = 0
		# Close session with all users
		for this_member in lobby_members:
			# Make sure this isn't your Steam ID
			if this_member['steam_id'] != steam_id:
				# Close the P2P session
				Steam.closeP2PSessionWithUser(this_member['steam_id'])
		# Clear the local lobby list
		lobby_members.clear()

func create_lobby() -> void:
	if lobby_id == 0:
		print("Creating lobby")
		Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, 3)
		is_host = true
	else:
		print("ERROR: Cannot create a lobby, as you are already in a lobby.")

func _on_lobby_created(error: int, this_lobby_id: int) -> void:
	if error == 1:
		lobby_id = this_lobby_id
		print("Created a lobby: %s" % lobby_id)
		Steam.setLobbyJoinable(lobby_id, true)
		Steam.setLobbyData(lobby_id, "owner_id", str(steam_id))
		Steam.setLobbyData(lobby_id, "owner_name", Steam.getPersonaName())
		Steam.setLobbyData(lobby_id, "lobby_name", Steam.getPersonaName() + "'s Lobby")
		# allow p2p connections to fallback to being relayed
		# through steam if necessary
		var set_relay: bool = Steam.allowP2PPacketRelay(true)
		print("Allowing Steam to be relay backup: %s" % set_relay)
	else:
		print("Failure creating lobby: %s" % error)

func read_all_p2p_packets(read_count: int = 0) -> void:
	if read_count >= PACKET_READ_LIMIT:
		return
	if Steam.getAvailableP2PPacketSize(0) > 0:
		read_p2p_packet()
		read_all_p2p_packets(read_count + 1)

func _on_p2p_session_request(remote_id: int) -> void:
	var requester: String = Steam.getFriendPersonaName(remote_id)
	print("%s is requesting a P2P session" % requester)
	
	Steam.acceptP2PSessionWithUser(remote_id)
	make_p2p_handshake()

func read_p2p_packet() -> void:
	var packet_size: int = Steam.getAvailableP2PPacketSize(0)
	if packet_size > 0:
		var this_packet: Dictionary = Steam.readP2PPacket(packet_size, 0)
		if this_packet.is_empty() or this_packet == null:
			print("WARNING: read an empty packet with non-zero size!")
		
		# get remote user ID
		#var packet_sender: int = this_packet['remote_steam_id']
		var packet_code: PackedByteArray = this_packet['data']
		var readable_data: Dictionary = bytes_to_var(packet_code.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP))
		
		do_stuff_with_packet(readable_data)

func _on_p2p_session_connect_fail(this_steam_id: int, session_error: int) -> void:
	# If no error was given
	if session_error == 0:
		print("WARNING: Session failure with %s: no error given" % this_steam_id)
	# Else if target user was not running the same game
	elif session_error == 1:
		print("WARNING: Session failure with %s: target user not running the same game" % this_steam_id)
	# Else if local user doesn't own app / game
	elif session_error == 2:
		print("WARNING: Session failure with %s: local user doesn't own app / game" % this_steam_id)
	# Else if target user isn't connected to Steam
	elif session_error == 3:
		print("WARNING: Session failure with %s: target user isn't connected to Steam" % this_steam_id)
	# Else if connection timed out
	elif session_error == 4:
		print("WARNING: Session failure with %s: connection timed out" % this_steam_id)
	# Else if unused
	elif session_error == 5:
		print("WARNING: Session failure with %s: unused" % this_steam_id)
	# Else no known error
	else:
		print("WARNING: Session failure with %s: unknown error %s" % [this_steam_id, session_error])

func get_lobby_info(this_lobby_id: int):
	print("Getting info for lobby %s" % str(this_lobby_id))
	var data: Dictionary
	var error = Steam.requestLobbyData(this_lobby_id)
	# wait for the lobby data to update
	await Steam.lobby_data_update
	if not error:
		print("WARNING: Failure to get lobby data for lobby %s" % str(this_lobby_id))
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
	print("Finding all friends online")
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
	print("Lobby data updated")

func _on_loaded_avatar(user_id: int, avatar_size: int, avatar_buffer: PackedByteArray) -> void:
	var avatar_image: Image = Image.create_from_data(avatar_size, avatar_size, false, Image.FORMAT_RGBA8, avatar_buffer)
	if avatar_size > 128:
		avatar_image.resize(128, 128, Image.INTERPOLATE_LANCZOS)
	var avatar_texture: ImageTexture = ImageTexture.create_from_image(avatar_image)
	avatar_list[user_id] = avatar_texture
