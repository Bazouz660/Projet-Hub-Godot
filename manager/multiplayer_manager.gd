extends Node

@onready var peer = ENetMultiplayerPeer.new()
@export var player_scene: PackedScene = preload("res://scene/player/player.tscn")
var world_scene = preload("res://scene/level/main_level.tscn").instantiate()
var active_player : Player = null
var player_list = {}
signal player_connected(player)
signal player_disconnected(player_id)
signal host_disconnected
var external_ip = ""
var port = 8080

func forward_port():
	var upnp = UPNP.new()
	var result = upnp.discover()
	if result == UPNP.UPNP_RESULT_SUCCESS:
		if upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():
			var map_result_udp = upnp.add_port_mapping(port, port, "godot_udp", "UDP", 0)
			var map_result_tcp = upnp.add_port_mapping(port, port, "godot_tcp", "TCP", 0)
			if not map_result_udp == UPNP.UPNP_RESULT_SUCCESS:
				upnp.add_port_mapping(port, port, "", "UDP")
			if not map_result_tcp == UPNP.UPNP_RESULT_SUCCESS:
				upnp.add_port_mapping(port, port, "", "TCP")
	external_ip = upnp.query_external_address()
	print("External IP: " + external_ip)
	upnp.delete_port_mapping(port, "UDP")
	upnp.delete_port_mapping(port, "TCP")

func host_game():
	get_tree().root.add_child(world_scene)
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	multiplayer.peer_disconnected.connect(_remove_player)
	# Spawn the host's player immediately
	call_deferred("_add_player", multiplayer.get_unique_id())
	print("Host unique ID: ", multiplayer.get_unique_id())  # Should print 1

func join_game(ip : String, host_port : int):
	get_tree().root.add_child(world_scene)
	peer.create_client(ip, host_port)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_disconnected.connect(_remove_player)
	# Don't spawn a player immediately when joining

func _add_player_to_list(player):
	player_list[player.name] = player

func _add_player(id):
	if not active_player and id == multiplayer.get_unique_id():
		# This is the local player
		var player = player_scene.instantiate()
		player.name = str(id)
		world_scene.get_node("SubViewportContainer/SubViewport/World/SpawnPoint").add_child(player)
		active_player = player
		_add_player_to_list(player)
		player_connected.emit(player)
	elif id != multiplayer.get_unique_id():
		# This is a remote player
		var player = player_scene.instantiate()
		player.name = str(id)
		world_scene.get_node("SubViewportContainer/SubViewport/World/SpawnPoint").add_child(player)
		_add_player_to_list(player)
		player_connected.emit(player)

func _remove_player(id):
	if str(id) in player_list:
		var player = player_list[str(id)]
		player_list.erase(str(id))
		if player:
			player.queue_free()
		player_disconnected.emit(id)
	print("Player " + str(id) + " disconnected")
	
	if id == 1:
		# Host has disconnected
		print("Host (ID: 1) has disconnected.")
		emit_signal("host_disconnected")
		_on_host_disconnetion()
		# Handle host disconnection (e.g., notify players, shutdown, etc.)

func _exit_tree():
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()

@rpc("any_peer", "reliable")
func _on_host_disconnetion():
	# Handle what to do on the peers when the host disconnects
	get_tree().quit()
