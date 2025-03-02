extends StaticBody3D
class_name TerrainChunk

# --- Static Variables & Configuration ---
static var config: TerrainConfig
static var generation_time_samples: Array[float] = []
static var max_samples: int = 1000
static var sample_index: int = 0
static var sample_array_filled: bool = false
static var biomes_label_index: Dictionary[String, Biome] = {}
static var biomes_index_label: Dictionary[int, Biome] = {}
static var biomes: Array[Biome]
static var max_height: float = - INF
static var min_height: float = INF
static var border_mesh: BoxMesh

# --- Constants ---
const CELL_SIZE: float = 0.25

# --- Public Instance Variables ---
var generating: bool = false
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# --- Private Instance Variables ---
var collision_object: CollisionShape3D
var mesh_instance: MeshInstance3D
var water_mesh_instance: MeshInstance3D
#var occluder_instance: OccluderInstance3D
var grid_position: Vector2i
var height_data: PackedFloat32Array = []
var biome_data: PackedInt32Array = []
var task_id: int

var continentalness_data: PackedFloat32Array
var erosion_data: PackedFloat32Array
var peaks_and_valleys_data: PackedFloat32Array
var humidity_data: PackedFloat32Array
var temperature_data: PackedFloat32Array
var difficulty_data: PackedFloat32Array

# Pre-calculated constants (set in _init)
var size: int
var vertex_count: int
var cells_per_side: int
var world_offset_x: float
var world_offset_z: float
var vertex_factor: float
var safe_vertex_count: int
var grid_size: int
var occupied_grid: PackedByteArray
var time_to_generate
var debug_mesh: MeshInstance3D

# --- Signals ---
signal _generated(meshes: Dictionary)
signal generated(position: Vector2i)

# --- Static Methods ---
static func set_config(p_config: TerrainConfig) -> void:
	config = p_config
	biomes = config.biomes
	generation_time_samples.resize(max_samples)
	border_mesh = TerrainChunkMesh._generate_chunk_borders_debug_mesh()

	_setup_shader_parameters()

func _toggle_debug_view(state: bool) -> void:
	debug_mesh.visible = state

static func _setup_shader_parameters():
	var shader_material = config.material

	var colors: Array[Color] = []
	var height_ranges: Array[Vector2] = []
	var humidity_ranges: Array[Vector2] = []
	var temperature_ranges: Array[Vector2] = []
	var difficulty_ranges: Array[Vector2] = []

	for biome in biomes:
		colors.append(biome.color)
		height_ranges.append(biome.height_range)
		humidity_ranges.append(biome.humidity_range)
		temperature_ranges.append(biome.temperature_range)
		difficulty_ranges.append(biome.difficulty_range)

		# Build lookup tables
		biomes_label_index[biome.label] = biome
		biomes_index_label[biome.id] = biome

		if biome.height_range.y > max_height:
			max_height = biome.height_range.y
		if biome.height_range.x < min_height:
			min_height = biome.height_range.x

	shader_material.set_shader_parameter("biome_colors", colors)
	shader_material.set_shader_parameter("height_ranges", height_ranges)
	shader_material.set_shader_parameter("humidity_ranges", humidity_ranges)
	shader_material.set_shader_parameter("temperature_ranges", temperature_ranges)
	shader_material.set_shader_parameter("difficulty_ranges", difficulty_ranges)
	shader_material.set_shader_parameter("biome_count", biomes.size())
	shader_material.set_shader_parameter("max_height", max_height)
	shader_material.set_shader_parameter("min_height", min_height)

static func sample_height(world_x: float, world_z: float) -> float:
	# Delegate to the TerrainNoise module’s static function.
	return TerrainChunkNoise.sample_height(world_x, world_z)

static func normalize_noise_value(value: float) -> float:
	return (value + 1.0) / 2.0

# --- Instance Methods ---

func _init(p_grid_position: Vector2i):
	size = config.chunk_size
	vertex_count = int(size * config.vertex_per_meter) + 1 # Calculate vertices based on density
	grid_position = p_grid_position
	cells_per_side = int(size / CELL_SIZE)
	world_offset_x = grid_position.x * size
	world_offset_z = grid_position.y * size
	vertex_factor = CELL_SIZE * config.vertex_per_meter
	safe_vertex_count = vertex_count - 1
	grid_size = cells_per_side * cells_per_side
	occupied_grid = PackedByteArray()
	occupied_grid.resize(grid_size)
	occupied_grid.fill(0)

func _ready():
	_generated.connect(_on_chunk_generated)
	mesh_instance = MeshInstance3D.new()
	water_mesh_instance = MeshInstance3D.new()
	water_mesh_instance.position.x += size * 0.5
	water_mesh_instance.position.z += size * 0.5

	collision_object = CollisionShape3D.new()
	collision_object.position.x += size * 0.5
	collision_object.position.z += size * 0.5

	debug_mesh = MeshInstance3D.new()
	debug_mesh.mesh = border_mesh
	debug_mesh.material_override = config.chunk_borders_material
	debug_mesh.visible = config.show_chunk_borders
	debug_mesh.position.x += size * 0.5
	debug_mesh.position.z += size * 0.5

	#occluder_instance = OccluderInstance3D.new()

	add_child(debug_mesh)
	add_child(collision_object)
	#add_child(occluder_instance)

	add_child(water_mesh_instance)
	add_child(mesh_instance)

func generate():
	time_to_generate = Time.get_ticks_msec()
	if generating:
		print("Chunk already generating")
		return
	generating = true
	task_id = WorkerThreadPool.add_task(_generate)

func get_height_at_world_position(world_position: Vector3) -> float:
	# Convert world position to local position relative to this chunk.
	var local_x = world_position.x - (grid_position.x * size)
	var local_z = world_position.z - (grid_position.y * size)

	# Clamp the local coordinates to ensure they fall within [0, size].
	local_x = clamp(local_x, 0.0, size)
	local_z = clamp(local_z, 0.0, size)

	# Convert to vertex coordinates.
	var x = int(local_x * config.vertex_per_meter)
	var z = int(local_z * config.vertex_per_meter)

	# Clamp the indices to ensure they’re within the valid vertex range.
	x = clamp(x, 0, vertex_count - 1)
	z = clamp(z, 0, vertex_count - 1)

	return height_data[z * vertex_count + x]


func is_position_in_chunk(world_position: Vector3) -> bool:
	var local_x = world_position.x - (grid_position.x * size)
	var local_z = world_position.z - (grid_position.y * size)
	return local_x >= 0.0 and local_x <= size and local_z >= 0.0 and local_z <= size

func set_height_at_world_position(world_position: Vector3, height: float) -> void:
	# Convert world position to local position relative to chunk
	var local_x = world_position.x - (grid_position.x * size)
	var local_z = world_position.z - (grid_position.y * size)

	# Check if the position is within this chunk's bounds
	if local_x < 0.0 or local_x > size or local_z < 0.0 or local_z > size:
		#print("Error setting height at world position: ", world_position, " is outside chunk bounds.")
		return

	# Convert to vertex coordinates
	var x = int(local_x * config.vertex_per_meter)
	var z = int(local_z * config.vertex_per_meter)

	# Check bounds (due to possible floating point issues)
	if x < 0 or x >= vertex_count or z < 0 or z >= vertex_count:
		# print("Error setting height at world position: ", world_position,
		# 	" local_x: ", local_x, " local_z: ", local_z,
		# 	" x: ", x, " z: ", z, " vertex_count: ", vertex_count)
		return

	height_data[z * vertex_count + x] = height

func set_biome_at_world_position(world_position: Vector3, biome_id: int) -> void:
	# Convert world position to local position relative to chunk
	var local_x = world_position.x - (grid_position.x * size)
	var local_z = world_position.z - (grid_position.y * size)

	# Check if the position is within this chunk's bounds
	if local_x < 0.0 or local_x > size or local_z < 0.0 or local_z > size:
		#print("Error setting biome at world position: ", world_position, " is outside chunk bounds.")
		return

	# Convert to vertex coordinates
	var x = int(local_x * config.vertex_per_meter)
	var z = int(local_z * config.vertex_per_meter)

	# Check bounds (due to possible floating point issues)
	if x < 0 or x >= vertex_count or z < 0 or z >= vertex_count:
		# print("Error setting biome at world position: ", world_position,
		# 	" local_x: ", local_x, " local_z: ", local_z,
		# 	" x: ", x, " z: ", z, " vertex_count: ", vertex_count)
		return

	biome_data[z * vertex_count + x] = biome_id

func get_interpolated_height_at_world_position(world_position: Vector3) -> float:
	var x_floor: float = floor(world_position.x)
	var z_floor: float = floor(world_position.z)
	var h00 = get_height_at_world_position(Vector3(x_floor, 0.0, z_floor))
	var h01 = get_height_at_world_position(Vector3(x_floor + 1.0, 0.0, z_floor))
	var h10 = get_height_at_world_position(Vector3(x_floor, 0.0, z_floor + 1.0))
	var h11 = get_height_at_world_position(Vector3(x_floor + 1.0, 0.0, z_floor + 1.0))
	var x_ratio = world_position.x - x_floor
	var z_ratio = world_position.z - z_floor
	var h0: float = lerp(h00, h01, x_ratio)
	var h1: float = lerp(h10, h11, x_ratio)
	return lerp(h0, h1, z_ratio)

static func calculate_terrain_normal(chunk: TerrainChunk, world_position: Vector3) -> Vector3:
	# Sample height at neighboring points
	var sample_distance = 1.0 / chunk.config.vertex_per_meter

	var h_center = world_position.y
	var h_right = chunk.get_interpolated_height_at_world_position(
		Vector3(world_position.x + sample_distance, 0.0, world_position.z))
	var h_forward = chunk.get_interpolated_height_at_world_position(
		Vector3(world_position.x, 0.0, world_position.z + sample_distance))
	var h_left = chunk.get_interpolated_height_at_world_position(
		Vector3(world_position.x - sample_distance, 0.0, world_position.z))
	var h_back = chunk.get_interpolated_height_at_world_position(
		Vector3(world_position.x, 0.0, world_position.z - sample_distance))

	# Calculate vectors along the surface
	var right_vec = Vector3(sample_distance, h_right - h_center, 0.0)
	var forward_vec = Vector3(0.0, h_forward - h_center, sample_distance)
	var left_vec = Vector3(- sample_distance, h_left - h_center, 0.0)
	var back_vec = Vector3(0.0, h_back - h_center, - sample_distance)

	# Calculate normals with cross products and average them
	var normal1 = right_vec.cross(forward_vec).normalized()
	var normal2 = forward_vec.cross(left_vec).normalized()
	var normal3 = left_vec.cross(back_vec).normalized()
	var normal4 = back_vec.cross(right_vec).normalized()

	var normal = (normal1 + normal2 + normal3 + normal4).normalized()

	# Make sure normal points upward (not strictly necessary but often desirable)
	if normal.y < 0:
		normal = - normal

	return normal

func _get_local_coords(world_position: Vector2) -> Vector2i:
	var chunk_start_x = grid_position.x * size - (1.0 / config.vertex_per_meter)
	var chunk_start_z = grid_position.y * size - (1.0 / config.vertex_per_meter)
	var x = int(world_position.x - chunk_start_x) * config.vertex_per_meter
	var y = int(world_position.y - chunk_start_z) * config.vertex_per_meter
	return Vector2i(x, y)

func _2d_to_1d(x: int, y: int) -> int:
	return y * vertex_count + x

func _2d_to_1dv(v: Vector2i) -> int:
	return v.y * vertex_count + v.x

func _1d_to_2d(index: int) -> Vector2:
	var x = index % vertex_count
	var y = index / vertex_count
	return Vector2(x, y)

func get_index_from_world_coords(world_x: float, world_z: float) -> int:
	var local_x = world_x - (grid_position.x * size)
	var local_z = world_z - (grid_position.y * size)
	var x = int(local_x * config.vertex_per_meter)
	var z = int(local_z * config.vertex_per_meter)
	var adjusted_x = x + 3
	var adjusted_z = z + 3
	var extended_vertex_count = vertex_count + 6
	return adjusted_z * extended_vertex_count + adjusted_x

func get_occupied_grid_index(x: float, z: float) -> int:
	# Convert the world position to the chunk's local space.
	var local_x = x - (grid_position.x * size)
	var local_z = z - (grid_position.y * size)

	# Determine which cell the position falls into by dividing by CELL_SIZE.
	var cell_x = int(local_x / CELL_SIZE)
	var cell_z = int(local_z / CELL_SIZE)

	# Check bounds to ensure the cell is within the chunk.
	if cell_x < 0 or cell_x >= cells_per_side or cell_z < 0 or cell_z >= cells_per_side:
		return -1 # or handle the out-of-bounds case as needed

	# Convert the 2D cell coordinate into a 1D array index.
	return cell_z * cells_per_side + cell_x


func _funny_randf(from: float, to: float) -> float:
	return rng.randf_range(from, to)

func _apply_structure_pos(structure: Structure):
	structure.position.y = structure.data.position.y

func _generate() -> void:
	# Seed the random generator
	rng.seed = hash(config.world_seed + hash(grid_position.x * grid_position.y))
	height_data.resize(vertex_count * vertex_count)
	biome_data.resize(vertex_count * vertex_count)

	TerrainChunkNoise._generate_noise_data(self)

	# Step 2: (NEW) Apply structure deformations.
	# You can call a new module/method that iterates over the structures
	# planned for this chunk and adjusts height_data accordingly.
	TerrainChunkStructures._apply_deformations(self)

	var mesh := TerrainChunkMesh._generate_mesh(self)
	var collision_shape := TerrainChunkMesh.create_heightmap_collision(self)
	#var occluder_shape := TerrainChunkMesh.create_occluder_shape(mesh)
	var water_mesh := TerrainChunkMesh._generate_water_mesh(self)
	var feature_positions: Dictionary[Vector2i, Array] = TerrainChunkFeatures._generate_features_positions(self)
	var data = {
		"mesh": mesh,
		"collision_shape": collision_shape,
		#"occluder_shape": occluder_shape,
		"water_mesh": water_mesh,
		"feature_positions": feature_positions
	}
	_generated.emit.call_deferred(data)
	generated.emit.call_deferred(grid_position)

func _on_chunk_generated(data: Dictionary) -> void:
	time_to_generate = Time.get_ticks_msec() - time_to_generate
	if sample_index >= max_samples - 1:
		sample_index = 0
		sample_array_filled = true
	else:
		sample_index += 1
	generation_time_samples[sample_index] = time_to_generate
	generating = false
	mesh_instance.mesh = data["mesh"]
	collision_object.shape = data["collision_shape"]
	water_mesh_instance.mesh = data["water_mesh"]
	#occluder_instance.occluder = data["occluder_shape"]
	mesh_instance.material_override = config.material
	water_mesh_instance.material_override = config.water_material
	water_mesh_instance.position.y = config.sea_level
	TerrainChunkFeatures._instantiate_features(self, data["feature_positions"])

func _instantiate_feature(feature: Feature, p_position: Vector3) -> void:
	TerrainChunkFeatures._instantiate_feature(self, feature, p_position)

func _instantiate_instances(feature: Feature, positions: Array) -> void:
	TerrainChunkFeatures._instantiate_instances(self, feature, positions)

func _instantiate_multimesh(biome: Biome, feature: Feature, positions: Array) -> void:
	TerrainChunkFeatures._instantiate_multimesh(self, biome, feature, positions)

func _exit_tree():
	if !WorkerThreadPool.is_task_completed(task_id):
		WorkerThreadPool.wait_for_task_completion(task_id)
