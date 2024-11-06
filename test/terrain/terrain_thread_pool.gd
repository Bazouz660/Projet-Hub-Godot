#terrain_thread_pool.gd
extends RefCounted
class_name TerrainThreadPool

var config : TerrainConfig
var terrain_system : TerrainSystem
var terrain_generator : TerrainGenerator

# Thread management
var thread_pool: Array[Thread]
var mutex: Mutex
var semaphore: Semaphore
var exit_thread: bool = false
var generation_queue: Array[Vector2] = []
var pending_results: Dictionary = {}  # chunk_pos: TerrainWorkResult
var active_jobs: int = 0


func _init(p_config : TerrainConfig, p_terrain_system : TerrainSystem, p_terrain_generator : TerrainGenerator):
	config = p_config
	terrain_system = p_terrain_system
	terrain_generator = p_terrain_generator
	mutex = Mutex.new()
	semaphore = Semaphore.new()
	_setup_thread_pool()

func _setup_thread_pool():
	thread_pool.clear()
	for i in range(config.max_concurrent_jobs):
		var thread = Thread.new()
		thread.start(_thread_function)
		thread_pool.append(thread)


func _queue_chunk_generation(chunk_pos: Vector2, chunks : Dictionary):
	mutex.lock()
	if not generation_queue.has(chunk_pos):
		generation_queue.append(chunk_pos)
		active_jobs += 1
		
		# Create empty chunk as placeholder
		var chunk = TerrainChunk.new(config)
		chunks[chunk_pos] = chunk
		terrain_system.add_child(chunk)
		chunk.position = Vector3(
			chunk_pos.x * config.chunk_size * config.grid_size,
			0,
			chunk_pos.y * config.chunk_size * config.grid_size
		)
	mutex.unlock()
	
	semaphore.post()  # Wake up a worker thread


func _thread_function():
	while true:
		semaphore.wait()  # Wait for work
		
		mutex.lock()
		if exit_thread:
			mutex.unlock()
			break
			
		if generation_queue.is_empty():
			mutex.unlock()
			continue
			
		var chunk_pos = generation_queue.pop_front()
		mutex.unlock()

		# Generate terrain data
		var result = terrain_generator._generate_terrain_data(chunk_pos)
		
		# Store result
		mutex.lock()
		pending_results[chunk_pos] = result
		mutex.unlock()
		
		# Notify main thread
		call_deferred("_check_pending_results")


func _check_pending_results():
	mutex.lock()
	var completed_chunks = pending_results.keys()
	
	for chunk_pos in completed_chunks:
		var result = pending_results[chunk_pos]
		terrain_system._apply_generation_result(result)
		pending_results.erase(chunk_pos)
		active_jobs -= 1
	
	mutex.unlock()
	
func _cleanup_threads():
	mutex.lock()
	exit_thread = true
	mutex.unlock()
	
	# Wake up all threads so they can exit
	for i in range(thread_pool.size()):
		semaphore.post()
	
	# Wait for all threads to finish
	for thread in thread_pool:
		thread.wait_to_finish()
	
	thread_pool.clear()


func _exit_tree():
	if not Engine.is_editor_hint():
		_cleanup_threads()
