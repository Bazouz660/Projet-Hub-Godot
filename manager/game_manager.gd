extends Node
class_name GameManager

@onready var peer = ENetMultiplayerPeer.new()
@export var player_scene: PackedScene = preload("res://scene/player/player.tscn")

@onready var world = $World
@onready var gui = $GUI

signal player_connected(player)
signal player_disconnected(player_id)
signal host_disconnected

var main_level_scene = preload("res://scene/level/main_level.tscn")
var active_player : Player = null
var player_list = {}

var current_3d_scene = null
var current_gui_scene = null

var external_ip = ""
var port = 8080

func _ready():
	Global.game_manager = self
	current_gui_scene = $GUI/MainMenu

func change_gui_scene(new_scene : String, delete: bool = true, keep_running: bool = false) -> void:
	if current_gui_scene != null:
		if delete:
			current_gui_scene.queue_free() # Removes node entirely
		elif keep_running:
			current_gui_scene.visible = false # Keep in memory and running
		else:
			gui.remove_child(current_gui_scene) # Keep in memory, doesn't run
	var new = load(new_scene).instantiate()
	gui.add_child(new)
	current_gui_scene = new

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
	# Set scene to world
	world.get_node("SubViewportContainer/SubViewport").add_child(main_level_scene.instantiate())
	peer.create_server(8080)
	multiplayer.multiplayer_peer = peer
	# Connect signals
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	# Add the local player
	var my_id = multiplayer.get_unique_id()
	_add_player(my_id)

func join_game(ip : String, host_port : int):
	# Set scene to world
	world.get_node("SubViewportContainer/SubViewport").add_child(main_level_scene.instantiate())
	peer.create_client(ip, host_port)
	multiplayer.multiplayer_peer = peer
	# Connect signals
	multiplayer.connected_to_server.connect(_connected_to_server)
	multiplayer.connection_failed.connect(_connection_failed)
	multiplayer.server_disconnected.connect(_server_disconnected)
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)

func _connected_to_server():
	print("Connected to server")
	var my_id = multiplayer.get_unique_id()
	_add_player(my_id)

func _connection_failed():
	print("Connection failed")

func _server_disconnected():
	print("Server disconnected")
	# Handle disconnection if needed

func _peer_connected(id):
	if id == multiplayer.get_unique_id():
		# Ignore ourselves; we've already added our player
		return
	print("Peer connected: ", id)
	_add_player(id)

func _peer_disconnected(id):
	print("Peer disconnected: ", id)
	# Remove the player node
	var player = world.get_node("SubViewportContainer/SubViewport/MainLevel").get_node(str(id))
	if player:
		player.queue_free()

func _add_player(id):
	var player = player_scene.instantiate()
	player.name = str(id)
	world.get_node("SubViewportContainer/SubViewport/MainLevel").add_child(player)
