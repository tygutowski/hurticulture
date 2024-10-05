extends Node

var lobby_id: int = 0
var lobby_members: Array[Dictionary] = []
var steam_id: int = -1
var steam_username: String = ''
var nickname: String = 'player'

const PACKET_READ_LIMIT = 32

func _init():
	OS.set_environment("SteamAppId", str(480))
	OS.set_environment("SteamGameId", str(480))

func _ready() -> void:
	initialize_steam()
	connect_signals()
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()

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

func instance_players():
	for player in lobby_members:
		print(player)

func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	print("Lobby joined")
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = this_lobby_id
		get_lobby_members()
		make_p2p_handshake()
		instance_players()
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
	
	#reopen lobby list

func _on_lobby_join_requested(this_lobby_id: int, friend_id: int) -> void:
	var owner_name: String = Steam.getFriendPersonaName(friend_id)
	
	print("Joining %s's lobby" % owner_name)
	
	join_lobby(this_lobby_id)

func get_lobby_members() -> void:
	lobby_members.clear()
	var number_of_members: int = Steam.getNumLobbyMembers(lobby_id)
	for this_member in range(0, number_of_members):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, this_member)
		
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
		lobby_members.append({
			"steam_id"   : member_steam_id,
			"steam_name" : member_steam_name
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
		"message" : "handshake",
		"from"    : steam_id,
	})

#when the lobby is updated
func _on_lobby_chat_updated(_this_lobby_id: int, change_id: int, _making_change_id: int, chat_state: int) -> void:
	var changer_name: String = Steam.getFriendPersonaName(change_id)
	# If a player has joined the lobby
	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		print("%s has joined the lobby." % changer_name)
	# Else if a player has left the lobby
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
		print("%s has left the lobby." % changer_name)
	# Else if a player has been kicked
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_KICKED:
		print("%s has been kicked from the lobby." % changer_name)
	# Else if a player has been banned
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_BANNED:
		print("%s has been banned from the lobby." % changer_name)
	# Else there was some unknown change
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
		
		get_tree().change_scene_to_file("res://environment/world.tscn")
	else:
		print("ERROR: Cannot create a lobby, as you are already in a lobby.")

func _on_lobby_created(error: int, this_lobby_id: int) -> void:
	if error == 1:
		lobby_id = this_lobby_id
		print("Created a lobby: %s" % lobby_id)
		Steam.setLobbyJoinable(lobby_id, true)
		Steam.setLobbyData(lobby_id, "owner", str(steam_id))
		Steam.setLobbyData(lobby_id, "name", str(Steam.getPersonaName()) + "'s Lobby")
		
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
		var packet_sender: int = this_packet['remote_steam_id']
		var packet_code: PackedByteArray = this_packet['data']
		
		var readable_data: Dictionary = bytes_to_var(packet_code.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP))
		print("Packet: %s" % readable_data)
		
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

func get_lobby_info(lobby_id: int):
	var data: Dictionary
	var error = Steam.requestLobbyData(lobby_id)
	if not error:
		print("WARNING: Failure to get lobby data for lobby %s" % str(lobby_id))
		return null
	data["owner"] = Steam.getLobbyData(lobby_id, "owner")
	data["name"] = Steam.getLobbyData(lobby_id, "name")
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

func _on_lobby_data_update(success: int, lobby_id: int, member_id: int) -> void:
	print("Lobby data updated")
	
