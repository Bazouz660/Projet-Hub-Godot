@tool
extends GodotIK
class_name LegIK

@onready var effector: GodotIKEffector = %Effector
@onready var pole_constraint: PoleBoneConstraint = %PoleBoneConstraint

@export var skeleton: Skeleton3D

@onready var ankle_raycast: RayCast3D = %AnkleRaycast
@onready var ankle_raycast_mesh: MeshInstance3D = %AnkleCollisionPointMesh
@onready var target_mesh: MeshInstance3D = %TargetMesh
@onready var bone_position_mesh: MeshInstance3D = $BonePositionMesh
@onready var thigh_bone_position_mesh: MeshInstance3D = $ThighBonePositionMesh
@onready var knee_bone_position_mesh: MeshInstance3D = $KneeBonePositionMesh
@onready var foot_bone_position_mesh: MeshInstance3D = $FootBonePositionMesh
@onready var knee_direction_mesh: Node3D = $KneeDirectionMesh

@export var align_foot_modifier: AlignSkeletonModifier3D
# @export var max_foot_align_distance: float = 0.2 # The maximum distance from the foot to the ground for the influence
# @export var foot_align_lerp_speed: float = 10.0 # Rate constant for exponential smoothing. Higher is faster.
@export var animator: AnimationMixer:
	set(value):
		if value:
			value.current_animation_changed.connect(func(_name: String):
				# Reset the lowest foot position when the animation changes
				lowest_foot_position_y = INF
				lowest_toe_position_y = INF
				highest_foot_position_y = - INF
				print("Animation changed: ", name)
		)
		animator = value

@export var LOWER_LEG_BONE_INDEX := 3
@export var FOOT_BONE_INDEX := 4
@export var TOE_BONE_INDEX := 5

@export var offset: float = 0.1 # The offset to apply to the foot position (The distance between the ankle and the sole of the foot)
@export var smoothing_speed: float = 25.0 # Rate constant for exponential smoothing. Higher is faster.
@export var foot_on_ground_epsilon: float = 0.05 # Epsilon for checking if the foot is on the ground
@export var influence_anticipation_height: float = 0.05 # How much 'earlier' (in meters above ground contact point) to apply full influence

const MAX_DELTA = 1.0 / 30.0 # Corresponds to a minimum of 30 FPS

var foot_vertical_velocity: float = 0.0 # The vertical velocity of the foot
var last_foot_position: Vector3 = Vector3.ZERO # The last height of the foot
var lowest_foot_position_y: float = INF # The lowest height of the foot
var lowest_toe_position_y: float = INF # The lowest height of the toe
var highest_foot_position_y: float = - INF # The highest height of the foot
var local_foot_position: Vector3
var toe_local_position: Vector3
var knee_position: Vector3 = Vector3.ZERO # The position of the knee

var last_ground_check: float = 0.0 # The last ground check result
var max_height_difference: float = 0.0 # The maximum height difference between the foot and the ground

var new_influence: float = 0.0 # The new influence value for the align foot modifier

# Called when the node enters the scene tree for the first time.
func _ready():
	if get_parent() is Skeleton3D:
		skeleton = get_parent()
		last_foot_position = skeleton.get_bone_global_pose(FOOT_BONE_INDEX).origin

	effector.bone_idx = FOOT_BONE_INDEX
	effector.chain_length = 3
	effector.transform_mode = GodotIKEffector.PRESERVE_ROTATION
	pole_constraint.bone_idx = LOWER_LEG_BONE_INDEX

	# if align_foot_modifier:
	# 	align_foot_modifier.bone_idx = FOOT_BONE_INDEX
	# 	remove_child(align_foot_modifier)
	# 	skeleton.add_child.call_deferred(align_foot_modifier, false, Node.INTERNAL_MODE_BACK)

func is_almost_equal(a: float, b: float, epsilon: float = 0.001) -> bool:
	return abs(a - b) < epsilon

func check_foot_on_ground() -> bool:
	# Check if the foot is supposed to be on the ground
	if is_almost_equal(lowest_foot_position_y, local_foot_position.y, foot_on_ground_epsilon + (pow(max_height_difference, 5) * 0.5)):
		return true

	return false

func check_toe_on_ground() -> bool:
	# Update the lowest toe position
	if toe_local_position.y < lowest_toe_position_y:
		lowest_toe_position_y = toe_local_position.y

	# Check if the toe is supposed to be on the ground
	if is_almost_equal(lowest_toe_position_y, toe_local_position.y, foot_on_ground_epsilon + (pow(max_height_difference, 5) * 0.5)):
		return true

	return false

func is_anim_grounded(delta: float) -> bool:
	var on_ground = (check_toe_on_ground() and check_foot_on_ground()) as float

	# interpolate the on ground check
	# print("Last ground check: ", last_ground_check)
	var lerp_alpha = clamp(60.0 * delta * animator.speed_scale, 0.0, 1.0)
	on_ground = lerp(last_ground_check, on_ground, lerp_alpha)
	on_ground = clamp(on_ground, 0.0, 1.0)
	last_ground_check = on_ground


	# print("Toe on ground: ", on_ground)
	return is_almost_equal(on_ground, 1.0, 0.001)

# Check how flat the foot is on the ground
func check_foot_flatness() -> float:
	# Check the difference in height between the toe and the foot
	var toe_height_difference = absf(toe_local_position.y - local_foot_position.y)

	# Compute the distance from the toe to the foot
	var toe_to_foot_distance = (toe_local_position - local_foot_position).length()

	# Compute the angle between the toe and the foot
	var angle = acos(toe_height_difference / toe_to_foot_distance)

	return angle

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not effector or not skeleton or not animator or not active:
		return

	# Clamp delta to avoid issues with very low/unstable FPS
	delta = min(delta, MAX_DELTA)

	var lerp_factor = clamp(smoothing_speed * delta, 0.0, 1.0)

	# if the window is not focused, do not update the IK
	if not get_window().has_focus():
		return


	# get the untransformed position of the foot

	local_foot_position = skeleton.get_bone_global_pose(FOOT_BONE_INDEX).origin
	set_deferred("last_foot_position", local_foot_position)

	if local_foot_position.y > highest_foot_position_y:
		highest_foot_position_y = local_foot_position.y

	if local_foot_position.y < lowest_foot_position_y:
		lowest_foot_position_y = local_foot_position.y

	max_height_difference = highest_foot_position_y - lowest_foot_position_y

	toe_local_position = skeleton.get_bone_global_pose(TOE_BONE_INDEX).origin

	var global_foot_position := (skeleton.global_transform * skeleton.get_bone_global_pose(FOOT_BONE_INDEX)).origin
	bone_position_mesh.global_position = global_foot_position

	var current_animated_bone_pos = global_foot_position
	var new_effector_pos = current_animated_bone_pos

	ankle_raycast.global_position.x = global_foot_position.x
	ankle_raycast.global_position.z = global_foot_position.z

	ankle_raycast.force_raycast_update()

	if ankle_raycast.is_colliding():
		var collision_point = ankle_raycast.get_collision_point()
		var collision_normal = ankle_raycast.get_collision_normal()

		align_foot_modifier.surface_normal = lerp(align_foot_modifier.surface_normal, -collision_normal, delta * 10.0)

		var foot_target_height := global_foot_position.y

		ankle_raycast_mesh.global_position = collision_point

		var anim_is_grounded = is_anim_grounded(delta)

		if not anim_is_grounded:
			target_mesh.material_override.albedo_color = Color.YELLOW
			new_effector_pos.y = lerp(effector.global_position.y, foot_target_height, lerp_factor)
			new_influence = 0.0
		else:
			target_mesh.material_override.albedo_color = Color.GREEN
			new_effector_pos.y = lerp(effector.global_position.y, collision_point.y + offset, lerp_factor)
			new_influence = 1.0


	else: # No collision
		new_influence = 0.0

	var thigh_position = (skeleton.global_transform * skeleton.get_bone_global_pose(LOWER_LEG_BONE_INDEX - 1)).origin
	thigh_bone_position_mesh.global_position = thigh_position

	knee_position = (skeleton.global_transform * skeleton.get_bone_global_pose(LOWER_LEG_BONE_INDEX)).origin
	knee_bone_position_mesh.global_position = knee_position

	var foot_position = (skeleton.global_transform * skeleton.get_bone_global_pose(FOOT_BONE_INDEX)).origin
	foot_bone_position_mesh.global_position = foot_position

	# Calculate knee direction in world space
	var thigh_to_knee_dir_world = (knee_position - thigh_position).normalized()
	var foot_to_knee_dir_world = (knee_position - foot_position).normalized()
	var knee_direction_world = (foot_to_knee_dir_world + thigh_to_knee_dir_world).normalized() # Renamed from knee_direction

	# Update the knee direction mesh (uses world-space direction)
	if is_instance_valid(knee_direction_mesh):
		knee_direction_mesh.global_position = knee_position
		if knee_direction_world.length_squared() > 0.0001: # Check to avoid issues if direction is zero
			knee_direction_mesh.global_rotation = Transform3D().looking_at(knee_direction_world, Vector3.UP).basis.get_euler()
		else:
			knee_direction_mesh.global_basis = Basis.IDENTITY

	# For the pole_constraint, the direction typically needs to be in the skeleton's local space
	# to remain correct when the skeleton itself is rotated.
	# Transform the world-space knee_direction to the skeleton's local space.
	var knee_direction_local = skeleton.global_transform.basis.inverse() * knee_direction_world
	pole_constraint.pole_direction = knee_direction_local # Use local direction

	# Update the effector position
	effector.global_position = lerp(effector.global_position, new_effector_pos, lerp_factor)


	align_foot_modifier.influence = lerp(align_foot_modifier.influence, new_influence, lerp_factor)
