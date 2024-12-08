extends Node3D

@export var min_max_influence: Vector2 = Vector2(0.03, 0.9)
@export var foot_height_offset: float = 0.05
@export var raycast_height_offset: float = 0.1
@export var rotation_lerp_speed: float = 10.0
@export var prediction_distance: float = 0.2 # How far ahead to predict foot positions
@export var velocity_smoothing: float = 0.1 # Smoothing factor for velocity calculation

@onready var right_target_container = $right_target_container
@onready var left_target_container = $left_target_container
@onready var ik_interpolation_left = $ik_interpolation_left
@onready var ik_interpolation_right = $ik_interpolation_right
@onready var ray_cast_left = $RayCastLeft
@onready var left_foot = $LeftFoot
@onready var ray_cast_right = $RayCastRight
@onready var right_foot = $RightFoot
@onready var right_target = $right_target_container/right_target
@onready var left_target = $left_target_container/left_target
@onready var ik_left = $"../GeneralSkeleton/IKLeft"
@onready var ik_right = $"../GeneralSkeleton/IKRight"
@export var animation_player: AnimationPlayer
@export var character: CharacterBody3D
@export var skeleton: Skeleton3D

var previous_position: Vector3
var current_velocity: Vector3

@export var exceptions: Array[CollisionObject3D] = []

func _ready():
	ik_left.start()
	ik_right.start()

	previous_position = global_position

	for exception in exceptions:
		ray_cast_left.add_exception(exception)
		ray_cast_right.add_exception(exception)

func align_to_normal(target: Node3D, normal: Vector3, bone_attach: BoneAttachment3D) -> void:
	normal = normal.normalized()
	var up_vector = Vector3.UP
	var rotation_axis = up_vector.cross(normal).normalized()
	var rotation_angle = up_vector.angle_to(normal)

	# Store the original Y rotation
	var original_y_rotation = target.global_transform.basis.get_euler().y

	var rotation_transform
	if rotation_axis.length_squared() > 0.0001:
		rotation_transform = Transform3D().rotated(rotation_axis, rotation_angle)
	else:
		rotation_transform = Transform3D()

	var current_transform = target.global_transform
	var current_basis = current_transform.basis.orthonormalized()
	var target_basis = (rotation_transform.basis * self.global_transform.basis).orthonormalized()

	var current_quat = Quaternion(current_basis)
	var target_quat = Quaternion(target_basis)
	var interpolated_quat = current_quat.slerp(target_quat, rotation_lerp_speed * get_physics_process_delta_time())

	# Apply the rotation
	target.global_transform.basis = Basis(interpolated_quat)

	# Reapply the original Y rotation
	var euler_rotation = target.global_transform.basis.get_euler()
	euler_rotation.y = original_y_rotation
	target.global_transform.basis = Basis.from_euler(euler_rotation)


func update_velocity():
	var current_position = global_position
	var frame_velocity = (current_position - previous_position) / get_physics_process_delta_time()
	current_velocity = current_velocity.lerp(frame_velocity, velocity_smoothing)
	previous_position = current_position

func get_predicted_position(base_position: Vector3) -> Vector3:
	# Project the velocity onto the horizontal plane
	var horizontal_velocity = current_velocity
	horizontal_velocity.y = 0

	# Only predict if we're actually moving
	if horizontal_velocity.length_squared() > 0.01:
		return base_position + horizontal_velocity.normalized() * prediction_distance * current_velocity.length()
	return base_position

func update_ik_target_pos(target: Marker3D, target_container: Node3D, raycast: RayCast3D, bone_attach: BoneAttachment3D):
	var bone_pos = bone_attach.global_transform.origin

	# Get predicted position based on velocity
	var predicted_pos = get_predicted_position(bone_pos)

	# Update raycast position with prediction
	raycast.global_position = predicted_pos
	raycast.global_position.y += raycast_height_offset

	if raycast.is_colliding():
		var hit_point = raycast.get_collision_point()
		var normal = raycast.get_collision_normal()

		# Smoothly move the target to the predicted position
		var target_pos = hit_point
		target_pos.y += foot_height_offset
		target_container.global_position = target_container.global_position.lerp(target_pos, 0.5)

		# Align to surface normal
		align_to_normal(target_container, normal, bone_attach)

func _physics_process(_delta: float):
	update_velocity()
	update_ik_target_pos(left_target, left_target_container, ray_cast_left, left_foot)
	update_ik_target_pos(right_target, right_target_container, ray_cast_right, right_foot)

	ik_left.influence = clamp(ik_interpolation_left.transform.origin.y, min_max_influence.x, min_max_influence.y)
	ik_right.influence = clamp(ik_interpolation_right.transform.origin.y, min_max_influence.x, min_max_influence.y)
