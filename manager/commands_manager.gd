extends Node

var mouse_mode: Input.MouseMode = Input.MOUSE_MODE_CAPTURED


func register_commands():
	Console.console_opened.connect(func():
		SceneManager.disable_player_input = true
		mouse_mode = Input.get_mouse_mode()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	)
	Console.console_closed.connect(func():
		SceneManager.disable_player_input = false
		Input.set_mouse_mode(mouse_mode)
	)

	Console.enable_on_release_build = true


	Console.add_command("time_set", set_time, ["time"], 1, "Sets the time of day.")
	Console.add_command("time_scale", set_time_scale, ["scale"], 1, "Sets the time scale.")
	Console.add_command("players_list", list_players, [], 0, "Lists all players.")
	Console.add_command("tp", tp, ["player_to", "player_from"], 1, "Teleports to a player.")
	Console.add_command("give", give, ["player_id", "item_id", "amount"], 2, "Gives an item to a player.")
	Console.add_command("kick", kick, ["player_id"], 1, "Kicks a player.")
	Console.add_command("set_health", _set_health, ["player_id", "health"], 2, "Sets the health of a player.")

	print("Commands registered.")

func set_time(time: String) -> void:

	if time == "day":
		time = "9"
	elif time == "night":
		time = "21"
	elif time == "noon":
		time = "12"
	elif time == "midnight":
		time = "0"

	# Convert time to float
	if not time.is_valid_float():
		Console.print_error("Invalid time. It must be a float.")
		return
	var time_float = time.to_float()
	TimeManager.set_time_of_day(time_float)

func set_time_scale(scale: String) -> void:
	if not scale.is_valid_float():
		Console.print_error("Invalid scale. It must be a float.")
		return
	var scale_float = scale.to_float()
	TimeManager.time_scale = scale_float

func list_players() -> void:
	var players = MultiplayerManager.players
	if players.size() == 0:
		Console.print_line("No players connected.")
		return
	for player in players:
		var me: bool = player.to_int() == MultiplayerManager.active_player_id
		if me:
			Console.print_line("Player ID: " + player + " (You)")
		else:
			Console.print_line("Player ID: " + player)

func tp(player_to: String, player_from: String = "") -> void:
	if player_from == "":
		player_from = str(MultiplayerManager.active_player_id)

	var player_from_node = MultiplayerManager.players.get(player_from)
	if player_from_node == null:
		Console.print_error("Player: " + player_from + " not found.")
		return
	var player_to_node = MultiplayerManager.players.get(player_to)
	if player_to_node == null:
		Console.print_error("Player: " + player_to + " not found.")
		return
	player_from_node.rpc_set_position.rpc(player_to_node.global_position + Vector3(0.5, 0, 0))
	Console.print_line("Teleported player " + player_from + " to player " + player_to + ".")

func give(player_id: String, item_id: String, amount: String = "1") -> void:
	var player = MultiplayerManager.players.get(player_id)
	if player == null:
		Console.print_error("Player: " + player_id + " not found.")
		return
	if not amount.is_valid_int() or amount.to_int() <= 0:
		Console.print_error("Invalid amount. It must be a positive integer.")
		return
	if not ItemRegistry.items.has(item_id):
		Console.print_error("Item: " + item_id + " not found.")
		return

	var amount_int = amount.to_int()

	if player_id != str(MultiplayerManager.active_player_id):
		_give.rpc(player_id, item_id, amount_int)
	else:
		_give(player_id, item_id, amount_int)

	Console.print_line("Gave " + player_id + " " + amount + " of " + item_id + ".")

@rpc("any_peer", "call_remote", "reliable")
func _give(player_id: String, item_id: String, amount: int) -> void:
	var player = MultiplayerManager.players.get(player_id)
	player.inventory.add_item_by_id(item_id, amount)

func kick(player_id: String) -> void:
	if not MultiplayerManager.is_host:
		Console.print_error("You must be the host to kick a player.")
		return
	if player_id == str(MultiplayerManager.active_player_id):
		Console.print_error("You can't kick yourself.")
		return
	var player = MultiplayerManager.players.get(player_id)
	if player == null:
		Console.print_error("Player: " + player_id + " not found.")
		return
	MultiplayerManager.peer.disconnect_peer(player_id.to_int())
	Console.print_line("Kicked player " + player_id + ".")


func _set_health(player_id: String, health: String) -> void:
	var player = MultiplayerManager.players.get(player_id)
	if player == null:
		Console.print_error("Player: " + player_id + " not found.")
		return
	if not health.is_valid_float() or health.to_float() < 0:
		Console.print_error("Invalid health. It must be a positive integer.")
		return
	player.resources.set_health(health.to_float())
	Console.print_line("Set health of " + player_id + " to " + health + ".")