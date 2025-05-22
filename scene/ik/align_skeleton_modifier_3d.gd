@tool
extends SkeletonModifier3D
class_name AlignSkeletonModifier3D

@export var bone_idx: int
@export var surface_normal: Vector3 = - Vector3.UP # The world-space normal vector to align to.
@export var bone_axis_to_align: Vector3 = Vector3.UP # The local axis of the bone to align.

@export var local_to_skeleton: bool = true # If true, the world-space surface_normal is transformed to be relative to the skeleton's Y-axis orientation. If false, it's used as a raw world-space normal, and calculations are done in world space.

func _process_modification() -> void:
	var skeleton: Skeleton3D = get_skeleton()
	if skeleton == null:
		return

	if not active:
		# If the modifier is not active, we can skip the alignment
		return

	if surface_normal == Vector3.ZERO or bone_axis_to_align == Vector3.ZERO:
		return

	var current_bone_pose_in_calc_space: Transform3D
	var target_normal_in_calc_space: Vector3

	if local_to_skeleton:
		# Operate in skeleton-local space
		current_bone_pose_in_calc_space = skeleton.get_bone_global_pose(bone_idx)
		# Original logic: transform the world-space surface_normal to be relative to the skeleton's Y-axis orientation.
		target_normal_in_calc_space = surface_normal.rotated(Vector3.UP, -skeleton.global_transform.basis.get_euler().y).normalized()
	else:
		# Operate in world space
		current_bone_pose_in_calc_space = skeleton.global_transform * skeleton.get_bone_global_pose(bone_idx)
		target_normal_in_calc_space = surface_normal.normalized() # Use world-space surface normal directly

	if target_normal_in_calc_space == Vector3.ZERO: # Should be caught by initial check, but good for safety
		return

	var current_bone_basis = current_bone_pose_in_calc_space.basis
	var local_bone_axis_normalized = bone_axis_to_align.normalized()

	# Core fix: Get the current direction of the bone's local axis in the working coordinate system (skeleton-local or world).
	var current_actual_bone_axis_direction = (current_bone_basis * local_bone_axis_normalized).normalized()

	if current_actual_bone_axis_direction == Vector3.ZERO:
		return # Should not happen if local_bone_axis_normalized is valid

	# Calculate the rotation needed to align the current_actual_bone_axis_direction with target_normal_in_calc_space.
	# Using a small epsilon to avoid issues with floating point comparisons for angle.
	var angle_to_target = current_actual_bone_axis_direction.angle_to(target_normal_in_calc_space)
	if angle_to_target < 0.0001: # Threshold for "no rotation needed"
		return

	var rotation_quat = Quaternion(current_actual_bone_axis_direction, target_normal_in_calc_space)

	# Apply this rotation to the bone's current basis.
	var new_bone_basis = (Basis(rotation_quat) * current_bone_basis).orthonormalized()

	var final_bone_pose_with_new_rotation = current_bone_pose_in_calc_space
	final_bone_pose_with_new_rotation.basis = new_bone_basis

	var final_bone_pose_skel_local: Transform3D
	if local_to_skeleton:
		final_bone_pose_skel_local = final_bone_pose_with_new_rotation
	else:
		# Convert the new world pose back to skeleton-local pose
		final_bone_pose_skel_local = skeleton.global_transform.affine_inverse() * final_bone_pose_with_new_rotation

	# Lerp between the initial and final poses
	var current_bone_pose = skeleton.get_bone_global_pose(bone_idx)

	var lerped_bone_pose = current_bone_pose.interpolate_with(final_bone_pose_skel_local, influence) # Adjust the interpolation factor as needed

	skeleton.set_bone_global_pose_override(bone_idx, lerped_bone_pose, 1.0)
