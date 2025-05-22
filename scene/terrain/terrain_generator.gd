extends Node3D
class_name TerrainGenerator

@export var config: TerrainConfig
@export var origin: Node3D = null
@export var enable_idle_updates: bool = false

@onready var structure_manager := %StructureManager as StructureManager
@onready var freecam := %FreeCam as FreeCam
var terrain_chunks: Dictionary[Vector2i, TerrainChunk] = {}
var timer := Timer.new()
var current_thread_usage: int = 0
var chunk_queue: Array[Vector2i] = []
var queued_chunks: Dictionary[Vector2i, bool] = {}

var max_refresh_queue_time: float = -1
var max_load_time: float = -1
var max_unload_time: float = -1

var spawn_chunk_loaded: bool = false

static var player_grid_position: Vector2i = Vector2i(0, 0)
var last_player_grid_position: Vector2i = Vector2i(0, 0)

func _ready():
	# Register commands
	_register_commands()

	config.setup()
	TerrainChunk.set_config(config)
	_generate_structure_data()

	# Set the view distance
	structure_manager.view_distance = config.view_distance * config.chunk_size
	config.view_distance_changed.connect(func(value: int):
		structure_manager.view_distance = config.view_distance * config.chunk_size
	)


	config.debug_toggled.connect(_on_toggle_debug_view)
	timer.timeout.connect(_refresh_chunks)
	timer.wait_time = config.update_rate
	timer.one_shot = false
	timer.start.call_deferred()
	add_child(timer)

	MultiplayerManager.active_player_loaded.connect(func(_id: int):
		origin = MultiplayerManager.active_player
		freecam.disable()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	)

func _set_player_on_ground():
	var player := MultiplayerManager.active_player
	var pos = player.global_transform.origin
	var height_at_pos = TerrainChunk.sample_height(pos.x, pos.z)
	pos = Vector3(pos.x, height_at_pos, pos.z)
	player.rpc_set_position.rpc(pos)


func _register_commands():
	Console.add_command("locate_biome", locate_biome, ["biome", "teleport"], 1, "Finds the nearest biome of given label. Optionally teleports the player to it.")
	Console.add_command("list_biomes", list_biomes, [], 0, "Lists all available biomes.")

func list_biomes():
	Console.print_line("Available biomes:")
	for biome in config.biomes_label_index.keys():
		Console.print_line("- " + biome)

func locate_biome(biome_label: String, teleport: String = "false"):
	if teleport != "" and not Utils.is_valid_bool(teleport):
		Console.print_error("Invalid teleport value: " + teleport)
		return

	Console.print_line("Locating biome: " + biome_label)
	var world_pos = origin.global_transform.origin
	if not config.biomes_label_index.has(biome_label):
		Console.print_error("Biome \"" + biome_label + "\" not found.")
		return
	var biome := config.biomes_label_index[biome_label]

	# This is a blocking operation, so we run it in a separate thread
	WorkerThreadPool.add_task(func():
		var start_time = Time.get_ticks_msec()
		var pos = TerrainChunkBiome.find_biome_world_position(biome, world_pos.x, world_pos.z, 20, 10000)

		var on_error = func(error: String):
			Console.print_error(error)
			return

		if pos == null:
			on_error.bind("Biome not found, timeout reached.").call_deferred()
			return

		var end_time = Time.get_ticks_msec()
		var time_ms = end_time - start_time

		var on_complete = func():
			Console.print_line("Biome found at: " + str(pos) + " in " + str(time_ms) + "ms")
			if Utils.string_to_bool(teleport):
				var heigh_at_pos = TerrainChunk.sample_height(pos.x, pos.z)
				(Console.console_commands["tp_position"].function as Callable).call(str(pos.x), str(heigh_at_pos + 1), str(pos.z))

		on_complete.call_deferred()

		, true)

func _generate_structure_data():
	var starting_region = Vector2(0, 0)
	structure_manager._generate_structures_for_region(starting_region)
	structure_manager.generated_regions[starting_region] = true
	structure_manager._update_structures()

func _on_toggle_debug_view(state: bool):
	for chunk in terrain_chunks.values():
		chunk._toggle_debug_view(state)

func _delete_chunk(chunk: TerrainChunk):
	terrain_chunks.erase(chunk.grid_position)
	chunk.queue_free()

func add_chunk_to_queue(grid_position: Vector2i):
	if not queued_chunks.has(grid_position):
		chunk_queue.push_back(grid_position)
		queued_chunks[grid_position] = true

func _process_chunk_queue():
	if chunk_queue.size() > 0 and current_thread_usage < config.max_threads:
		var grid_position = chunk_queue.pop_front()
		queued_chunks.erase(grid_position)
		_create_chunk(grid_position.x, grid_position.y)

func _create_chunk(x: int, z: int):
	# S'assurer que les structures sont générées pour cette région avant de créer le chunk
	var chunk_pos = Vector3(x * config.chunk_size, 0, z * config.chunk_size)
	structure_manager._ensure_structures_generated(chunk_pos)


	var chunk = TerrainChunk.new(Vector2i(x, z))
	chunk.position = chunk_pos
	add_child(chunk)
	terrain_chunks[chunk.grid_position] = chunk
	chunk.generate()
	current_thread_usage += 1

	chunk.generated.connect(on_chunk_generated)

	if !spawn_chunk_loaded and chunk.grid_position == player_grid_position:
		spawn_chunk_loaded = true
		chunk.generated.connect(func(_position: Vector2i):
			if MultiplayerManager.active_player != null:
				_set_player_on_ground()
			else:
				MultiplayerManager.active_player_loaded.connect(_set_player_on_ground)
		)

func on_chunk_generated(_grid_position: Vector2i):
	current_thread_usage -= 1

func world_to_grid_position(world_position: Vector3) -> Vector2i:
	return Vector2i(
		floori(world_position.x / config.chunk_size),
		floori(world_position.z / config.chunk_size)
	)

func _refresh_chunks():
	if origin == null:
		return

	player_grid_position = world_to_grid_position(origin.global_transform.origin)
	var start_time = Time.get_ticks_msec()
	_unload_chunks()
	var end_time = Time.get_ticks_msec()
	var time_ms = end_time - start_time
	#print("Unload time: ", time_ms, "ms")
	if time_ms > max_unload_time:
		max_unload_time = time_ms

	start_time = Time.get_ticks_msec()
	_load_chunks()
	end_time = Time.get_ticks_msec()
	time_ms = end_time - start_time
	#print("Load time: ", time_ms, "ms")
	if time_ms > max_load_time:
		max_load_time = time_ms

	start_time = Time.get_ticks_msec()
	_refresh_chunk_queue()
	end_time = Time.get_ticks_msec()
	time_ms = end_time - start_time
	#print("Queue time: ", time_ms, "ms")
	if time_ms > max_refresh_queue_time:
		max_refresh_queue_time = time_ms

func _unload_chunks():
	var view_distance_sq = config.view_distance * config.view_distance
	for chunk in terrain_chunks.values().duplicate():
		var delta = chunk.grid_position - player_grid_position
		if delta.x * delta.x + delta.y * delta.y > view_distance_sq and not chunk.generating:
			_delete_chunk.call_deferred(chunk)

func _load_chunks():
	var view_distance = config.view_distance
	var view_distance_sq = view_distance * view_distance
	for x in range(-view_distance, view_distance + 1):
		var x_sq = x * x
		if x_sq > view_distance_sq:
			continue
		for z in range(-view_distance, view_distance + 1):
			if x_sq + z * z > view_distance_sq:
				continue
			var check_position = Vector2i(x, z) + player_grid_position
			if not terrain_chunks.has(check_position):
				add_chunk_to_queue(check_position)

func _refresh_chunk_queue():
	var view_distance_sq = config.view_distance * config.view_distance

	# Clean up out-of-range queued chunks
	for i in range(chunk_queue.size() - 1, -1, -1):
		var grid_position = chunk_queue[i]
		var delta = grid_position - player_grid_position
		if delta.x * delta.x + delta.y * delta.y > view_distance_sq:
			chunk_queue.remove_at(i)
			queued_chunks.erase(grid_position)

	# Sort queue by distance to player (closest first)
	# This has a big impact on performance, I will need to find a better way to do this
	chunk_queue.sort_custom(_sort_positions)

func _sort_positions(a: Vector2i, b: Vector2i) -> int:
	var delta_a = a - player_grid_position
	var delta_b = b - player_grid_position
	return delta_a.x * delta_a.x + delta_a.y * delta_a.y < delta_b.x * delta_b.x + delta_b.y * delta_b.y

func _input(event: InputEvent):
	if event is InputEventKey:
		event = event as InputEventKey
		if event.pressed and event.keycode == KEY_ESCAPE and Input.is_key_label_pressed(KEY_SHIFT):
			get_tree().quit()

func is_chunk_loaded(world_position: Vector3) -> bool:
	var grid_position = world_to_grid_position(world_position)
	return terrain_chunks.has(grid_position)

func _process(_delta):
	if origin == null:
		return

	_process_chunk_queue()

	# var frame_time_ms = delta * 1000
	# if frame_time_ms > 8.0:
	# 	print("Frame time: ", frame_time_ms, "ms")

	var label = %Label as Label
	var world_pos := origin.global_transform.origin

	var continentalness = Utils.get_normalized_noise_2d(config.continentalness, world_pos.x, world_pos.z)
	var peaks_and_valeys = Utils.get_normalized_noise_2d(config.peaks_and_valeys, world_pos.x, world_pos.z)
	var erosion = Utils.get_normalized_noise_2d(config.erosion, world_pos.x, world_pos.z)

	var humidity = Utils.get_normalized_noise_2d(config.humidity, world_pos.x, world_pos.z)
	var temperature = Utils.get_normalized_noise_2d(config.temperature, world_pos.x, world_pos.z)
	var difficulty = Utils.get_normalized_noise_2d(config.difficulty, world_pos.x, world_pos.z)

	var height = TerrainChunk.sample_height(world_pos.x, world_pos.z)

	var biome = TerrainChunkBiome.determine_biome(world_pos.x, world_pos.z)

	var continentalness_str = "%.2f" % continentalness
	var peaks_and_valeys_str = "%.2f" % peaks_and_valeys
	var erosion_str = "%.2f" % erosion
	var humidity_str = "%.2f" % humidity
	var temperature_str = "%.2f" % temperature
	var difficulty_str = "%.2f" % difficulty
	var height_str = "%.2f" % height
	var x_str = "%.2f" % world_pos.x
	var y_str = "%.2f" % world_pos.y
	var z_str = "%.2f" % world_pos.z
	var biome_str = biome.label if biome != null else "None"

	label.text = "Continentalness: " + continentalness_str + "\n" \
		+"Peaks and Valeys: " + peaks_and_valeys_str + "\n" \
		+"Erosion: " + erosion_str + "\n" \
		+"Humidity: " + humidity_str + "\n" \
		+"Temperature: " + temperature_str + "\n" \
		+"Difficulty: " + difficulty_str + "\n" \
		+"Height: " + height_str + "\n" \
		+"X: " + x_str + "  Y: " + y_str + "  Z: " + z_str + "\n" \
		+"Biome: " + biome_str

func _exit_tree():
	print("Max unload time: ", max_unload_time, "ms")
	print("Max load time: ", max_load_time, "ms")
	print("Max refresh queue time: ", max_refresh_queue_time, "ms")
	var generation_time_samples = TerrainChunk.generation_time_samples

	var average_generation_time = 0
	var median_generation_time = 0

	if TerrainChunk.sample_array_filled:
		for sample in generation_time_samples:
			average_generation_time += sample
		average_generation_time /= generation_time_samples.size()
		median_generation_time = generation_time_samples[generation_time_samples.size() / 2]
		print("Average generation time: ", average_generation_time, "ms, samples: ", generation_time_samples.size())
		print("Median generation time: ", median_generation_time, "ms")
	else:
		for sample in range(TerrainChunk.sample_index):
			average_generation_time += generation_time_samples[sample]
		average_generation_time /= TerrainChunk.sample_index
		median_generation_time = generation_time_samples[TerrainChunk.sample_index / 2]
		print("Average generation time: ", average_generation_time, "ms, samples: ", TerrainChunk.sample_index)
		print("Median generation time: ", median_generation_time, "ms")
