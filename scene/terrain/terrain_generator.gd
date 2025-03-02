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

static var player_grid_position: Vector2i = Vector2i(0, 0)
var last_player_grid_position: Vector2i = Vector2i(0, 0)

func _ready():
	MultiplayerManager.active_player_loaded.connect(func(_id: int):
		origin = MultiplayerManager.active_player
		freecam.disable()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	)

	config.setup()
	TerrainChunk.set_config(config)
	structure_manager.view_distance = config.view_distance * config.chunk_size
	_generate_structure_data()


	config.debug_toggled.connect(_on_toggle_debug_view)
	timer.timeout.connect(_refresh_chunks)
	timer.wait_time = config.update_rate
	timer.one_shot = false
	timer.start.call_deferred()
	add_child(timer)

func _generate_structure_data():
	# We no longer pre-generate structures for the whole world
	# Instead, structures will be generated on-demand as the player explores
	# This is handled by the structure_manager._ensure_structures_generated method
	# You can still generate structures for the starting area if desired
	var starting_region = Vector2(0, 0)
	structure_manager._generate_structures_for_region(starting_region)

	# Mark the starting region as generated
	structure_manager.generated_regions[starting_region] = true

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
	var chunk = TerrainChunk.new(Vector2i(x, z))
	chunk.position = Vector3(x * config.chunk_size, 0, z * config.chunk_size)
	add_child(chunk)
	terrain_chunks[chunk.grid_position] = chunk
	chunk.generate()
	current_thread_usage += 1
	chunk.generated.connect(on_chunk_generated)

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
	for x in range(- view_distance, view_distance + 1):
		var x_sq = x * x
		if x_sq > view_distance_sq:
			continue
		for z in range(- view_distance, view_distance + 1):
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

# func _input(event):
# 	if event is InputEventKey:
# 		event = event as InputEventKey
# 		if event.pressed and event.keycode == KEY_ESCAPE:
# 			get_tree().quit()

func _process(_delta):
	if origin == null:
		return

	_process_chunk_queue()

	# var frame_time_ms = delta * 1000
	# if frame_time_ms > 8.0:
	# 	print("Frame time: ", frame_time_ms, "ms")

	var label = %Label as Label
	var world_pos := origin.global_transform.origin

	var continentalness = config.continentalness.get_noise_2d(world_pos.x, world_pos.z)
	var peaks_and_valeys = config.peaks_and_valeys.get_noise_2d(world_pos.x, world_pos.z)
	var erosion = config.erosion.get_noise_2d(world_pos.x, world_pos.z)

	var humidity = config.humidity.get_noise_2d(world_pos.x, world_pos.z)
	var temperature = config.temperature.get_noise_2d(world_pos.x, world_pos.z)
	var difficulty = config.difficulty.get_noise_2d(world_pos.x, world_pos.z)

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

# func _exit_tree():
# 	print("Max unload time: ", max_unload_time, "ms")
# 	print("Max load time: ", max_load_time, "ms")
# 	print("Max refresh queue time: ", max_refresh_queue_time, "ms")
# 	var generation_time_samples = TerrainChunk.generation_time_samples

# 	var average_generation_time = 0
# 	var median_generation_time = 0

# 	if TerrainChunk.sample_array_filled:
# 		for sample in generation_time_samples:
# 			average_generation_time += sample
# 		average_generation_time /= generation_time_samples.size()
# 		median_generation_time = generation_time_samples[generation_time_samples.size() / 2]
# 		print("Average generation time: ", average_generation_time, "ms, samples: ", generation_time_samples.size())
# 		print("Median generation time: ", median_generation_time, "ms")
# 	else:
# 		for sample in range(TerrainChunk.sample_index):
# 			average_generation_time += generation_time_samples[sample]
# 		average_generation_time /= TerrainChunk.sample_index
# 		median_generation_time = generation_time_samples[TerrainChunk.sample_index / 2]
# 		print("Average generation time: ", average_generation_time, "ms, samples: ", TerrainChunk.sample_index)
# 		print("Median generation time: ", median_generation_time, "ms")
