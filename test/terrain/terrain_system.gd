#terrain_system.gd
@tool
extends Node3D
class_name TerrainSystem

@export var player : CharacterBody3D = null
var config = preload("res://test/terrain_config.tres") as TerrainConfig

var thread_pool : TerrainThreadPool
var terrain_generator : TerrainGenerator

# Internal variables
var chunks = {}
var current_chunk = Vector2.ZERO
var rng = RandomNumberGenerator.new()
var loaded = false

static var instance : TerrainSystem

func _ready():
	if Engine.is_editor_hint():
		return
		
	instance = self
		
	config.biome_noise.noise.seed = config.seed
	config.height_noise.noise.seed = config.seed
	
	FeatureManager.set_config(config)
	
	for feature in config.features:
		FeatureManager.register_feature(feature)
	
	terrain_generator = TerrainGenerator.new(config)
			
	if config.use_threading:
		thread_pool = TerrainThreadPool.new(config, self, terrain_generator)
	
	rng.seed = config.seed
	_update_chunks()

	MultiplayerManager.active_player_loaded.connect(_set_player)
		
	config.terrain_material.set_shader_parameter("mountain_threshold", config.mountain_threshold)
	config.terrain_material.set_shader_parameter("forest_threshold", config.forest_threshold)
	config.terrain_material.set_shader_parameter("beach_threshold", config.beach_threshold)


func _set_player(_id):
	player = MultiplayerManager.active_player

func _update_chunks():
	if Engine.is_editor_hint():
		return
		
	var required_chunks = []
	for x in range(-config.view_distance, config.view_distance + 1):
		for z in range(-config.view_distance, config.view_distance + 1):
			required_chunks.append(current_chunk + Vector2(x, z))
	
	# Remove chunks that are too far
	for chunk_pos in chunks.keys():
		if not chunk_pos in required_chunks:
			chunks[chunk_pos].queue_free()
			chunks.erase(chunk_pos)
	
	# Add new chunks to generation queue
	for chunk_pos in required_chunks:
		if not chunks.has(chunk_pos):
			if config.use_threading:
				thread_pool._queue_chunk_generation(chunk_pos, chunks)
			else:
				_generate_chunk_immediate(chunk_pos)

func _generate_chunk_immediate(chunk_pos: Vector2):
	var result = terrain_generator._generate_terrain_data(chunk_pos)
	var chunk = TerrainChunk.new(config)
	chunks[chunk_pos] = chunk
	add_child(chunk)
	chunk.global_position = Vector3(
		chunk_pos.x * config.chunk_size * config.grid_size,
		0,
		chunk_pos.y * config.chunk_size * config.grid_size
	)
	_apply_generation_result(result)

func _process(_delta):
	if Engine.is_editor_hint():
		return
		
	if is_instance_valid(player):
		var player_chunk = get_chunk_pos(player.global_position)
		if player_chunk != current_chunk:
			current_chunk = player_chunk
			_update_chunks()

func get_current_biome() -> String:
	var world_x = int(player.global_position.x / config.grid_size)
	var world_z = int(player.global_position.z / config.grid_size)
	var biome_value = config.biome_noise.noise.get_noise_2d(world_x, world_z)
	
	if biome_value >= config.mountain_threshold:
		return "Mountain"
	elif biome_value >= config.forest_threshold:
		return "Forest"
	elif biome_value >= config.beach_threshold:
		return "Plains"
	else:
		return "Beach"
		
func is_in_water() -> bool:
	return player.global_position.y <= config.water_level

static func get_biome_material() -> String:
	
	if instance.is_in_water():
		return "water"
	
	var biome = instance.get_current_biome()
	match biome:
		"Mountain":
			return "rock"
		"Forest":
			return "grass"
		"Plains":
			return "grass"
		"Beach":
			return "sand"
	return "Unknown"

func get_chunk_pos(world_pos: Vector3) -> Vector2:
	return Vector2(
		floor(world_pos.x / (config.chunk_size * config.grid_size)),
		floor(world_pos.z / (config.chunk_size * config.grid_size))
	)
	
func _apply_generation_result(result: TerrainGenerator.WorkResult):
	if not chunks.has(result.chunk_pos):
		return  # Chunk was removed before generation completed
	
	var chunk = chunks[result.chunk_pos] as TerrainChunk
	
	# Create mesh from generation result
	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = result.mesh_data[0]  # vertices
	arrays[ArrayMesh.ARRAY_INDEX] = result.mesh_data[1]   # indices
	arrays[ArrayMesh.ARRAY_TEX_UV] = result.mesh_data[2]  # uvs
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	chunk.apply_mesh_data(array_mesh)
	
	# Apply feature results
	FeatureManager.apply_features(chunk, result.feature_data)
