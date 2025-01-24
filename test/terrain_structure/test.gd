extends Node3D

# Constants for terrain generation
@export var CHUNK_SIZE: int = 25:
	set(value):
		CHUNK_SIZE = value
		GRID_SIZE = CHUNK_SIZE * VERTICES_PER_METER
		#regenerate_terrain()

@export var VERTICES_PER_METER: int = 1:
	set(value):
		VERTICES_PER_METER = value
		GRID_SIZE = CHUNK_SIZE * VERTICES_PER_METER
		#regenerate_terrain()

var GRID_SIZE: int
@export var HEIGHT_SCALE = 2.0 # Maximum height of the terrain
@export var terrain_material: Material

# Noise generator for terrain
@export var noise = FastNoiseLite.new()
@export var blend_noise = FastNoiseLite.new()
@export var base_blend_distance: float = 3.0 # Base blend distance
@export var noise_scale: float = 0.5 # Scale of the noise for irregularity
@export var noise_strength: float = 1.0 # Strength of the noise effect

@export var multi_mesh: MultiMesh
@export var multi_mesh_instance: MultiMeshInstance3D
var terrain_mesh: MeshInstance3D
@export var collision_shape: CollisionShape3D
var height_data: PackedFloat32Array
@export var structures: Array[Node3D]
@export var features: Array[Node3D]

@export var update_interval = 0.1
var update_accumulator = 0.0

var thread_pool := ThreadPool.new(4)
var transforms: PackedVector3Array
var task_id: int = -1
var worker_running = false
var requested_update = true

# Cache for commonly used calculations
var _cached_basis_x_inv := Vector3.ZERO
var _cached_basis_y_inv := Vector3.ZERO
var _cached_basis_z_inv := Vector3.ZERO
var _cached_bounds := {}

func _ready():
	for feature in %Features.get_children():
		features.append(feature)
	multi_mesh_instance.multimesh = multi_mesh
	GRID_SIZE = CHUNK_SIZE * VERTICES_PER_METER
	initialize_height_data()
	generate_terrain()
	populate_surface()
	snap_features_to_terrain()

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and event.keycode == KEY_CTRL:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func snap_features_to_terrain():
	for feature in features:
		var position = feature.global_position
		position.y = get_terrain_height(Vector2(position.x, position.z))
		feature.global_position = position

func add_structure(p_position: Vector2) -> void:
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(4.0, 2.0, 4.0)

	var structure = MeshInstance3D.new()
	add_child(structure)

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.7, 0.7)
	structure.material_override = material
	structure.mesh = box_mesh
	structure.position = Vector3(p_position.x, 0, p_position.y)
	structure.position.y = get_terrain_height(Vector2(p_position.x, p_position.y)) + 1.0 / 2
	structure.rotation.y = randf() * PI # Random rotation for variety

	structures.append(structure)
	modify_terrain_for_structure(structure)

func calculate_obb(structure: Node3D) -> OBB:
	var aabb = structure.mesh.get_aabb()
	var center = structure.global_position
	var half_extents = aabb.size / 2
	var p_basis = structure.global_transform.basis
	return OBB.new(center, half_extents, p_basis)

func regenerate_terrain():
	requested_update = true
	initialize_height_data()
	adapt_terrain_to_structures()
	generate_terrain()
	snap_features_to_terrain()
	update_multimesh_instances()

func adapt_terrain_to_structures():
	for structure in structures:
		structure.position.y = (get_terrain_height(Vector2(structure.position.x, structure.position.z)) - 0.15)
		modify_terrain_for_structure(structure)

func _calculate_spatial_bounds(parent: Node3D, exclude_top_level_transform: bool) -> AABB:
	var bounds: AABB = AABB()
	if parent is VisualInstance3D:
		bounds = parent.get_aabb();

	for i in range(parent.get_child_count()):
		var child: Node3D = parent.get_child(i)
		if child:
			var child_bounds: AABB = _calculate_spatial_bounds(child, false)
			if bounds.size == Vector3.ZERO && parent:
				bounds = child_bounds
			else:
				bounds = bounds.merge(child_bounds)
	if bounds.size == Vector3.ZERO && !parent:
		bounds = AABB(Vector3.ZERO, Vector3.ZERO)
	if !exclude_top_level_transform:
		bounds = parent.transform * bounds
	return bounds

func _process(delta):
	update_accumulator += delta
	if update_accumulator >= update_interval:
		update_accumulator = 0.0
		regenerate_terrain()

func initialize_height_data():
	height_data.resize((GRID_SIZE + 1) * (GRID_SIZE + 1))
	for z in range(GRID_SIZE + 1):
		for x in range(GRID_SIZE + 1):
			var pos_x = float(x) / VERTICES_PER_METER
			var pos_z = float(z) / VERTICES_PER_METER
			var height = noise.get_noise_2d(pos_x, pos_z) * HEIGHT_SCALE
			height_data[_2d_coordinates_to_index(x, z)] = height

func _2d_coordinates_to_index(x: int, z: int) -> int:
	return z * (GRID_SIZE + 1) + x

func generate_terrain() -> void:
	# Pre-calculate array sizes
	var vertex_count := (GRID_SIZE + 1) * (GRID_SIZE + 1)
	var triangle_count := GRID_SIZE * GRID_SIZE * 6 # 6 vertices per quad (2 triangles)

	# Create arrays for mesh data
	var vertices := PackedVector3Array()
	vertices.resize(triangle_count) # Preallocate for all triangles

	# Optional: If you need UVs
	var uvs := PackedVector2Array()
	uvs.resize(triangle_count)

	# Create a single array for all vertex positions to avoid recreating Vector3s
	var positions := PackedVector3Array()
	positions.resize(vertex_count)

	# Pre-calculate all vertex positions in a single pass
	for z in range(GRID_SIZE + 1):
		var z_pos := float(z) / VERTICES_PER_METER
		var row_offset := z * (GRID_SIZE + 1)
		for x in range(GRID_SIZE + 1):
			positions[row_offset + x] = Vector3(
				float(x) / VERTICES_PER_METER,
				height_data[_2d_coordinates_to_index(z, x)],
				z_pos
			)

	# Generate triangles using direct array access
	var vertex_index := 0
	for z in range(GRID_SIZE):
		var row_offset := z * (GRID_SIZE + 1)
		var next_row_offset := (z + 1) * (GRID_SIZE + 1)

		for x in range(GRID_SIZE):
			var v0 := positions[row_offset + x]
			var v1 := positions[row_offset + x + 1]
			var v2 := positions[next_row_offset + x]
			var v3 := positions[next_row_offset + x + 1]

			# First triangle
			vertices[vertex_index] = v0
			vertices[vertex_index + 1] = v1
			vertices[vertex_index + 2] = v2

			# Second triangle
			vertices[vertex_index + 3] = v1
			vertices[vertex_index + 4] = v3
			vertices[vertex_index + 5] = v2

			# Optional: Add UVs if needed
			var uv_x := float(x) / GRID_SIZE
			var uv_z := float(z) / GRID_SIZE
			var uv_x_next := float(x + 1) / GRID_SIZE
			var uv_z_next := float(z + 1) / GRID_SIZE

			uvs[vertex_index] = Vector2(uv_x, uv_z)
			uvs[vertex_index + 1] = Vector2(uv_x_next, uv_z)
			uvs[vertex_index + 2] = Vector2(uv_x, uv_z_next)
			uvs[vertex_index + 3] = Vector2(uv_x_next, uv_z)
			uvs[vertex_index + 4] = Vector2(uv_x_next, uv_z_next)
			uvs[vertex_index + 5] = Vector2(uv_x, uv_z_next)

			vertex_index += 6

	# Create the mesh directly instead of using SurfaceTool
	var arr_mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs

	# Generate normals using raw arrays for better performance
	var normals := PackedVector3Array()
	normals.resize(triangle_count)
	for i in range(0, triangle_count, 3):
		var v0 := vertices[i]
		var v1 := vertices[i + 1]
		var v2 := vertices[i + 2]
		var normal := (v1 - v0).cross(v2 - v0).normalized()
		normals[i] = normal
		normals[i + 1] = normal
		normals[i + 2] = normal

	arrays[Mesh.ARRAY_NORMAL] = normals

	# Create or update the mesh
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	# Update MeshInstance3D
	if !is_instance_valid(terrain_mesh):
		terrain_mesh = MeshInstance3D.new()
		add_child(terrain_mesh)
		terrain_mesh.material_override = terrain_material

	terrain_mesh.mesh = arr_mesh

	# Update collision shape
	if !is_instance_valid(collision_shape):
		collision_shape = CollisionShape3D.new()
		add_child(collision_shape)

	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(vertices) # Direct vertex array instead of getting faces from mesh
	collision_shape.shape = shape

func get_terrain_height(p_position: Vector2) -> float:
	var x = int(p_position.x * VERTICES_PER_METER)
	var z = int(p_position.y * VERTICES_PER_METER)
	if x < 0 or x >= GRID_SIZE or z < 0 or z >= GRID_SIZE:
		return 0.0
	return height_data[_2d_coordinates_to_index(z, x)]

func get_interpolated_terrain_height(p_position: Vector2) -> float:
	var x = p_position.x * VERTICES_PER_METER
	var z = p_position.y * VERTICES_PER_METER
	var x0 = int(x)
	var z0 = int(z)
	var x1 = min(x0 + 1, GRID_SIZE)
	var z1 = min(z0 + 1, GRID_SIZE)
	var dx = x - x0
	var dz = z - z0
	var h00 = height_data[_2d_coordinates_to_index(z0, x0)]
	var h01 = height_data[_2d_coordinates_to_index(z0, x1)]
	var h10 = height_data[_2d_coordinates_to_index(z1, x0)]
	var h11 = height_data[_2d_coordinates_to_index(z1, x1)]
	var h0 = lerp(h00, h01, dx)
	var h1 = lerp(h10, h11, dx)
	return lerp(h0, h1, dz)

func get_rotated_bounds(obb: OBB, expanded_distance: float) -> Dictionary:
	# Use cached results if OBB hasn't changed
	var cache_key := "%s_%s_%s_%s" % [obb.center, obb.basis, obb.half_extents, expanded_distance]
	if _cached_bounds.has(cache_key):
		return _cached_bounds[cache_key]

	var expanded_half_extents := obb.half_extents + Vector3.ONE * expanded_distance

	# Calculate basis vectors once
	var basis_x := obb.basis.x * expanded_half_extents.x
	var basis_y := obb.basis.y * expanded_half_extents.y
	var basis_z := obb.basis.z * expanded_half_extents.z

	# Calculate min and max bounds directly without generating all corners
	var min_bound := obb.center
	var max_bound := obb.center

	# Add/subtract basis vectors to find extremes
	for i in 8:
		var x_component := basis_x if (i & 1) else -basis_x
		var y_component := basis_y if (i & 2) else -basis_y
		var z_component := basis_z if (i & 4) else -basis_z

		var point := obb.center + x_component + y_component + z_component

		min_bound = min_bound.min(point)
		max_bound = max_bound.max(point)

	var result := {"min": min_bound, "max": max_bound}
	_cached_bounds[cache_key] = result
	return result

func modify_terrain_for_structure(structure: Node3D) -> void:
	var obb := calculate_obb(structure)
	var expanded_bounds := get_rotated_bounds(obb, base_blend_distance + noise_strength)

	# Precalculate inverse basis vectors for distance calculations
	_cached_basis_x_inv = obb.basis.x / obb.half_extents.x
	_cached_basis_y_inv = obb.basis.y / obb.half_extents.y
	_cached_basis_z_inv = obb.basis.z / obb.half_extents.z

	# Calculate grid bounds
	var start_x := maxi(0, int(expanded_bounds.min.x * VERTICES_PER_METER))
	var end_x := mini(GRID_SIZE, int(expanded_bounds.max.x * VERTICES_PER_METER))
	var start_z := maxi(0, int(expanded_bounds.min.z * VERTICES_PER_METER))
	var end_z := mini(GRID_SIZE, int(expanded_bounds.max.z * VERTICES_PER_METER))

	# Precalculate target height
	var target_height := calculate_target_height(obb)

	# Precalculate common values
	var vertices_per_meter_inv := 1.0 / VERTICES_PER_METER
	var noise_scale_x := noise_scale * vertices_per_meter_inv
	var noise_scale_z := noise_scale * vertices_per_meter_inv

	# Create temporary arrays for batch processing
	var positions := PackedVector3Array()
	positions.resize((end_x - start_x + 1) * (end_z - start_z + 1))
	var pos_idx := 0

	# Batch process positions
	for z in range(start_z, end_z + 1):
		var z_pos := float(z) * vertices_per_meter_inv
		for x in range(start_x, end_x + 1):
			positions[pos_idx] = Vector3(
				float(x) * vertices_per_meter_inv,
				height_data[_2d_coordinates_to_index(z, x)],
				z_pos
			)
			pos_idx += 1

	# Process heights in batches
	pos_idx = 0
	for z in range(start_z, end_z + 1):
		for x in range(start_x, end_x + 1):
			var current_pos := positions[pos_idx]
			var distance := get_obb_distance_optimized(current_pos, obb)

			if distance <= 0.0:
				height_data[_2d_coordinates_to_index(z, x)] = target_height
			else:
				var noise_value := blend_noise.get_noise_2d(
					current_pos.x * noise_scale_x,
					current_pos.z * noise_scale_z
				)
				var effective_blend_distance := base_blend_distance + (noise_value * noise_strength)

				if distance < effective_blend_distance:
					var blend_factor := 1.0 - (distance / effective_blend_distance)
					blend_factor = ease(blend_factor, -2.0)
					var original_height := height_data[_2d_coordinates_to_index(z, x)]
					height_data[_2d_coordinates_to_index(z, x)] = lerp(original_height, target_height, blend_factor)

			pos_idx += 1

# Optimized OBB distance calculation using cached inverse basis
func get_obb_distance_optimized(point: Vector3, obb: OBB) -> float:
	var local_point := point - obb.center
	var projected := Vector3(
		local_point.dot(_cached_basis_x_inv),
		local_point.dot(_cached_basis_y_inv),
		local_point.dot(_cached_basis_z_inv)
	)

	var distance := Vector3(
		maxf(absf(projected.x) - 1.0, 0.0),
		maxf(absf(projected.y) - 1.0, 0.0),
		maxf(absf(projected.z) - 1.0, 0.0)
	)

	return distance.length()

func calculate_target_height(obb: OBB) -> float:
	const SAMPLE_POINTS := 9
	var total_height := 0.0
	var count := 0

	# Precalculate sine and cosine values
	var angles := PackedFloat32Array()
	angles.resize(SAMPLE_POINTS)
	var cosines := PackedFloat32Array()
	cosines.resize(SAMPLE_POINTS)
	var sines := PackedFloat32Array()
	sines.resize(SAMPLE_POINTS)

	for i in SAMPLE_POINTS:
		var angle := 2.0 * PI * float(i) / float(SAMPLE_POINTS)
		angles[i] = angle
		cosines[i] = cos(angle)
		sines[i] = sin(angle)

	# Calculate scale factors once
	var scale_x := obb.half_extents.x * 0.5
	var scale_z := obb.half_extents.z * 0.5

	for i in SAMPLE_POINTS:
		var local_sample := Vector3(
			cosines[i] * scale_x,
			0.0,
			sines[i] * scale_z
		)

		var world_sample := obb.center + obb.basis * local_sample
		var grid_x := int(world_sample.x * VERTICES_PER_METER)
		var grid_z := int(world_sample.z * VERTICES_PER_METER)

		if grid_x >= 0 and grid_x <= GRID_SIZE and grid_z >= 0 and grid_z <= GRID_SIZE:
			total_height += height_data[_2d_coordinates_to_index(grid_z, grid_x)]
			count += 1

	return total_height / maxf(count, 1.0)

# New function to update multimesh instances
func update_multimesh_instances():
	if !multi_mesh:
		return

	#update_multimesh_brute_force()
	update_multimesh_threaded()


func update_multimesh_brute_force():
	for i in range(multi_mesh.instance_count):
		var new_transform = multi_mesh.get_instance_transform(i)
		var new_position = new_transform.origin
		new_position.y = get_interpolated_terrain_height(Vector2(new_position.x, new_position.z))
		new_transform.origin = new_position
		multi_mesh.set_instance_transform(i, new_transform)

func update_multimesh_threaded():

	if !worker_running and requested_update:
		worker_running = true
		transforms = multi_mesh.transform_array.duplicate()
		var instance_count := multi_mesh.instance_count
		task_id = WorkerThreadPool.add_group_task(update_multimesh_chunk, instance_count)

	elif requested_update and WorkerThreadPool.is_group_task_completed(task_id):
		WorkerThreadPool.wait_for_group_task_completion(task_id)
		worker_running = false
		requested_update = false
		multi_mesh.transform_array = transforms.duplicate()


func update_multimesh_chunk(i: int):
	var start_index := 4 * i
	var origin_vector := transforms[start_index + 3]
	origin_vector.y = get_interpolated_terrain_height(Vector2(origin_vector.x, origin_vector.z))
	transforms[start_index + 3] = origin_vector


# populates a mesh with a multimesh
func populate_surface():
	# generate positions
	for i in range(multi_mesh.instance_count):
		var x = randf_range(0, CHUNK_SIZE)
		var z = randf_range(0, CHUNK_SIZE)
		# Use get_terrain_height which now includes structure modifications
		var y = get_terrain_height(Vector2(x, z))
		var p_position = Vector3(x, y, z)
		multi_mesh.set_instance_transform(i, Transform3D(Basis(), p_position))

	multi_mesh_instance.multimesh = multi_mesh


func _exit_tree():
	print("Shutting down thread pool")
	thread_pool.shutdown()
