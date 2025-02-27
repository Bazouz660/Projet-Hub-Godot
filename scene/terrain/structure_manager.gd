# StructureManager.gd
extends Node3D
class_name StructureManager

# Global array to hold all structure data (StructureData instances)
static var global_structures: Array[StructureData] = []

# Dictionary to track instantiated structures (StructureData -> Structure instance)
var instantiated_structures: Dictionary = {}
var view_distance: float = 300.0 # Match with chunk view distance
var timer: Timer

@export var structure_params: Array[StructureGenParams] = []

signal structure_generated(structure: Structure)

func _ready():
	# Create a timer to update structure visibility, similar to chunk loading
	timer = Timer.new()
	timer.wait_time = 1.0 # Update once per second
	timer.one_shot = false
	timer.timeout.connect(_update_structures)
	add_child(timer)
	timer.start()

	# Initialize structure generation parameters
	StructureGenerationManager.initialize(structure_params)

func _update_structures():
	# Get player position from the terrain generator
	var player_pos = Vector2(TerrainGenerator.player_grid_position.x, TerrainGenerator.player_grid_position.y)
	var player_pos_3d = Vector3(player_pos.x * TerrainChunk.config.chunk_size, 0, player_pos.y * TerrainChunk.config.chunk_size)

	# Generate structures in the region around the player if needed
	_ensure_structures_generated(player_pos_3d)

	# Load structures that are within view distance
	_load_structures(player_pos_3d)

	# Unload structures that are too far
	_unload_structures(player_pos_3d)
	_unload_distant_regions(player_pos_3d)

func _unload_distant_regions(player_pos: Vector3):
	# Get the squared view distance for faster comparisons
	var view_distance_sq = (view_distance * 2) * (view_distance * 2)

	# Check each generated region
	var regions_to_remove = []

	for region in generated_regions.keys():
		var region_center = Vector3(
			region.x * region_size + region_size * 0.5,
			0,
			region.y * region_size + region_size * 0.5
		)

		var dx = player_pos.x - region_center.x
		var dz = player_pos.z - region_center.z
		var distance_sq = dx * dx + dz * dz

		# If outside view distance, queue for removal
		if distance_sq > view_distance_sq:
			regions_to_remove.append(region)

	# Remove regions outside view distance
	for region in regions_to_remove:
		generated_regions.erase(region)

func _load_structures(player_pos: Vector3):
	# Get the squared view distance for faster comparisons
	var view_distance_sq = view_distance * view_distance

	# Check each structure in the global list
	for structure_data in global_structures:
		# Skip already instantiated structures
		if instantiated_structures.has(structure_data):
			continue

		# Calculate distance to structure (2D distance ignoring Y)
		var structure_pos = structure_data.position
		var dx = player_pos.x - structure_pos.x
		var dz = player_pos.z - structure_pos.z
		var distance_sq = dx * dx + dz * dz

		# If within view distance, instantiate the structure
		if distance_sq <= view_distance_sq:
			_instantiate_structure(structure_data)

func _unload_structures(player_pos: Vector3):
	# Get the squared view distance for faster comparisons
	var view_distance_sq = view_distance * view_distance

	# Check each instantiated structure
	var structures_to_remove = []

	for structure_data in instantiated_structures:
		var structure_pos = structure_data.position
		var dx = player_pos.x - structure_pos.x
		var dz = player_pos.z - structure_pos.z
		var distance_sq = dx * dx + dz * dz

		# If outside view distance, queue for removal
		if distance_sq > view_distance_sq:
			structures_to_remove.append(structure_data)

	# Remove structures outside view distance
	for structure_data in structures_to_remove:
		_remove_structure(structure_data)

func _instantiate_structure(structure_data: StructureData):
	var scene_to_use: PackedScene = structure_data.structure_scene

	# Create new structure instance
	var structure_instance := scene_to_use.instantiate() as Structure

	# Set position based on structure data
	structure_instance.position = Vector3(
		structure_data.position.x + structure_data.size.x * 0.5,
		structure_data.position.y,
		structure_data.position.z + structure_data.size.z * 0.5
	)

	# Apply rotation
	structure_instance.rotation_degrees = structure_data.rotation_degrees

	# Add to the scene
	add_child(structure_instance)

	# Register the instance
	instantiated_structures[structure_data] = structure_instance

	# Ensure structure has the correct data
	structure_instance.data = structure_data

	# Emit signal for external systems
	structure_generated.emit(structure_instance)

func _remove_structure(structure_data: StructureData):
	# Get the structure instance
	var structure_instance = instantiated_structures[structure_data]

	# Remove it from the scene
	if is_instance_valid(structure_instance):
		structure_instance.queue_free()

	# Remove from the tracking dictionary
	instantiated_structures.erase(structure_data)

# Dictionary to keep track of generated regions
var generated_regions = {}

# Region size (in world units)
var region_size = 256.0 # This should be adjusted based on your world scale

func _ensure_structures_generated(player_pos: Vector3):
	# Calculate the region the player is in
	var region_x = floor(player_pos.x / region_size)
	var region_z = floor(player_pos.z / region_size)

	# Check surrounding regions too (3x3 grid)
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var check_region = Vector2(region_x + dx, region_z + dz)

			# If this region hasn't been generated yet, generate it
			if not generated_regions.has(check_region):
				_generate_structures_for_region(check_region)
				generated_regions[check_region] = true

func _generate_structures_for_region(region_coords: Vector2):
	# Calculate region bounds in world space
	var region_min = Vector2(region_coords.x * region_size, region_coords.y * region_size)
	var region_max = Vector2(region_min.x + region_size, region_min.y + region_size)

	# Create a seeded RNG for deterministic generation
	var rng = RandomNumberGenerator.new()
	var region_seed = hash(str(region_coords) + str(TerrainChunk.config.world_seed))
	rng.seed = region_seed

	# Get structures for this region
	var structures = StructureGenerationManager.generate_structure_data_for_region(
		region_min, region_max, rng
	)

	# Check each structure for valid placement and register it
	for structure_data in structures:
		var aabb = AABB(structure_data.position, structure_data.size)
		var steepness = _check_terrain_steepness(aabb)
		var height = _get_average_height(aabb)
		aabb.position.y = height

		if can_place_structure(aabb) and steepness <= 0.1:
			register_structure(structure_data)

# Helper method to check terrain steepness within an AABB (check multiple points and compare their height differences, the higher the difference, the steeper the terrain)
func _check_terrain_steepness(aabb: AABB) -> float:
	var points = [
		Vector2(aabb.position.x, aabb.position.z),
		Vector2(aabb.position.x + aabb.size.x, aabb.position.z),
		Vector2(aabb.position.x, aabb.position.z + aabb.size.z),
		Vector2(aabb.position.x + aabb.size.x, aabb.position.z + aabb.size.z)
	]

	var max_diff = 0.0

	for point in points:
		var height = TerrainChunkNoise.sample_height(point.x, point.y)
		var height_x = TerrainChunkNoise.sample_height(point.x + 0.1, point.y)
		var height_z = TerrainChunkNoise.sample_height(point.x, point.y + 0.1)

		var diff_x = abs(height - height_x)
		var diff_z = abs(height - height_z)

		max_diff = max(max_diff, diff_x, diff_z)

	return max_diff

# get the average height of the terrain within an AABB
func _get_average_height(aabb: AABB) -> float:
	var total_height = 0.0
	var total_points = 0

	for x in range(int(aabb.position.x), int(aabb.position.x + aabb.size.x)):
		for z in range(int(aabb.position.z), int(aabb.position.z + aabb.size.z)):
			total_height += TerrainChunkNoise.sample_height(x, z)
			total_points += 1

	return total_height / total_points

static func register_structure(structure_data: StructureData) -> void:
	# Add structure data if not already present.
	if not global_structures.has(structure_data):
		global_structures.append(structure_data)

static func unregister_structure(structure_data: StructureData) -> void:
	global_structures.erase(structure_data)

# Returns an array of StructureData that intersect the given AABB.
static func get_structures_in_area(area: AABB) -> Array[StructureData]:
	var result: Array[StructureData] = []
	for structure_data in global_structures:
		var struct_aabb = AABB(structure_data.position, structure_data.size)
		if area.intersects(struct_aabb):
			result.append(structure_data)
	return result

static func can_place_structure(new_aabb: AABB) -> bool:
	# Iterate through already registered structures.
	for structure_data in global_structures:
		var existing_aabb = AABB(structure_data.position, structure_data.size)
		if new_aabb.intersects(existing_aabb):
			return false
	return true
