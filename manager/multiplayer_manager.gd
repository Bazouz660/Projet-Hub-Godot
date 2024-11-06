extends Node

@export var player_scene: PackedScene = preload("res://scene/player/player.tscn")
var level_scene_path : String = "res://test/worldgen_test_pretty.tscn"
var level_node_path : String = "SubViewportContainer/SubViewport/WorldManager" 

var root : Root

signal player_connected(id)
signal player_disconnected(player_id)
signal active_player_loaded
signal session_active

var is_host : bool

var peer: ENetMultiplayerPeer = null
var active_player : Player = null :
	set(value):
		active_player = value
		if is_instance_valid(active_player):
			active_player.ready.connect(func(): active_player_loaded.emit())
	
var self_id = 0
var players : Array

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
	# Ensure any existing connection is closed before hosting a new game
	close_connection()
	
	is_host = true
	
	# Set scene to world
	SceneManager.change_3d_scene(level_scene_path)
	await SceneManager.scene_loaded
	
	peer = ENetMultiplayerPeer.new()  # Create a new peer instance
	var error = peer.create_server(port)
	if error:
		print("Error creating server: ", error)
		return
	multiplayer.multiplayer_peer = peer
	session_active.emit()
	# Connect signals
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	# Add the local player
	self_id = multiplayer.get_unique_id()
	_add_player(self_id)
	
	print("My id: ", self_id)

func join_game(ip : String, host_port : int):
	# Ensure any existing connection is closed before joining a new game
	close_connection()
	
	is_host = false
	
	# Set scene to world
	SceneManager.change_3d_scene(level_scene_path)
	await SceneManager.scene_loaded
	
	peer = ENetMultiplayerPeer.new()  # Create a new peer instance
	var error = peer.create_client(ip, host_port)
	if error:
		print("Error creating client: ", error)
		return
	multiplayer.multiplayer_peer = peer
	# Connect signals
	multiplayer.connected_to_server.connect(_connected_to_server)
	multiplayer.connection_failed.connect(_connection_failed)
	multiplayer.server_disconnected.connect(_server_disconnected)
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)

func _connected_to_server():
	print("Connected to server")
	self_id = multiplayer.get_unique_id()
	print("My id: ", self_id)
	_add_player(self_id)
	active_player.rpc_set_position(Vector3(0, 5, 0))
	print("Active player position: ", active_player.global_position)

func _connection_failed():
	print("Connection failed")

func _server_disconnected():
	print("Server disconnected")
	close_connection()
	SceneManager.change_3d_scene("")
	SceneManager.change_gui_scene("res://scene/interface/main_menu/main_menu.tscn")

func _peer_connected(id):
	if id == multiplayer.get_unique_id():
		# Ignore ourselves; we've already added our player
		return
	print("Peer connected: ", id)
	_add_player(id)
	print(players)
	player_connected.emit(id)

func _peer_disconnected(id):
	print("Peer disconnected: ", id)
	# Remove the player node
	var player = root.world.get_node(level_node_path).get_node_or_null(str(id))
	if player:
		players.erase(player.name)
		player.queue_free()
	print(players)
	player_disconnected.emit(id)

func _add_player(id):
	var player = player_scene.instantiate() as Player
	player.name = str(id)
	players.append(player.name)
	if id == multiplayer.get_unique_id():
		active_player = player
	# Set the player's position here
	root.world.get_node(level_node_path).add_child(player)
	
func close_connection():
	if multiplayer.multiplayer_peer == null:
		print("No active connection to close")
		return

	# Common cleanup for both host and client
	_safe_disconnect(multiplayer.peer_connected, _peer_connected)
	_safe_disconnect(multiplayer.peer_disconnected, _peer_disconnected)

	# Clear the multiplayer peer
	multiplayer.multiplayer_peer = null
	peer = null
	
	# Clear players
	for player in players:
		var player_node = root.world.get_node(level_node_path).get_node_or_null(str(player))
		if player_node:
			player_node.queue_free()
	players.clear()
	active_player = null

	print("Connection closed")

# Helper function to safely disconnect signals
func _safe_disconnect(signal_obj, callback):
	if signal_obj.is_connected(callback):
		signal_obj.disconnect(callback)

@rpc
func server_shutdown():
	if not multiplayer.is_server():
		print("Server is shutting down")
		# Handle any client-side cleanup here
		close_connection()

@rpc("any_peer")
func client_disconnecting(client_id: int):
	if multiplayer.is_server():
		print("Client ", client_id, " is disconnecting")
		# Handle any server-side cleanup for the disconnecting client
		# This method will be called by clients before they disconnect
