extends SkeletonModifier3D
class_name AnimationLayerModifier3D

@export var animation_player: AnimationPlayer = null
@export var blend_time: float = 0.3
@export var affected_bones: Array[String] = []

var skeleton: Skeleton3D = null
var original_poses: Array[Transform3D] = []
var bone_mask: Array[bool] = []
var anim_progess: float = 0.0
var anim_accumulator: float = 0.0
var override_animation_name: String = ""
var previous_override_transforms = {}
var is_first_override = true

func _ready() -> void:
	# Get the skeleton reference
	active = false
	skeleton = get_skeleton()
	if not skeleton:
		push_warning("AnimationLayerModifier3D: No skeleton found!")
		return

	# Initialize bone arrays
	var bone_count = skeleton.get_bone_count()
	original_poses.resize(bone_count)
	bone_mask.resize(bone_count)

	enable_bones(affected_bones)

	print("BOne mask: ", bone_mask)

	original_poses = sample_bone_poses()

func _process_modification() -> void:
	if not skeleton:
		return

	# Store original poses
	for i in range(skeleton.get_bone_count()):
		original_poses[i] = skeleton.get_bone_pose(i)

	# Play the override animation
	_process_override_animation()


func _process_override_animation() -> void:
	var override_animation = animation_player.get_animation(override_animation_name)
	if not override_animation:
		push_error("AnimationLayerModifier3D: Animation not found: ", override_animation_name)
		return

	var anim_length = override_animation.length
	var loop_mode = override_animation.loop_mode

	if anim_progess > anim_length:
		if loop_mode == Animation.LOOP_NONE:
			anim_progess = anim_length
		else:
			anim_progess = fmod(anim_progess, anim_length)

	var blend_factor = min(1.0, anim_accumulator / blend_time)

	for track in override_animation.get_track_count():
		var path = override_animation.track_get_path(track)
		path = (path as String).split(":")[1]
		var bone_idx = skeleton.find_bone(path)

		if bone_idx != -1 and bone_mask[bone_idx]:
			var current_transform = skeleton.get_bone_pose(bone_idx)
			var new_transform = current_transform

			if override_animation.track_get_type(track) == Animation.TYPE_ROTATION_3D:
				var target_rotation = override_animation.rotation_track_interpolate(track, anim_progess)
				var start_quat = current_transform.basis.get_rotation_quaternion()

				# Utiliser la dernière pose d'override comme point de départ si disponible
				if not is_first_override and bone_idx in previous_override_transforms:
					start_quat = previous_override_transforms[bone_idx].basis.get_rotation_quaternion()

				var blended_quat = start_quat.slerp(target_rotation, blend_factor)
				new_transform.basis = Basis(blended_quat)

			elif override_animation.track_get_type(track) == Animation.TYPE_POSITION_3D:
				var target_position = override_animation.position_track_interpolate(track, anim_progess)
				var start_position = current_transform.origin

				# Utiliser la dernière pose d'override comme point de départ si disponible
				if not is_first_override and bone_idx in previous_override_transforms:
					start_position = previous_override_transforms[bone_idx].origin

				new_transform.origin = start_position.lerp(target_position, blend_factor)

			skeleton.set_bone_pose(bone_idx, new_transform)

			# Sauvegarder la transformation actuelle pour la prochaine transition
			if blend_factor >= 1.0:
				if not previous_override_transforms.has(bone_idx):
					previous_override_transforms[bone_idx] = Transform3D()
				previous_override_transforms[bone_idx] = new_transform

	var delta = get_process_delta_time()
	anim_progess += delta
	anim_accumulator += delta

	if blend_factor >= 1.0:
		is_first_override = false


func set_bone_mask(bone_idx: int, p_enabled: bool) -> void:
	if bone_idx >= 0 and bone_idx < bone_mask.size():
		bone_mask[bone_idx] = p_enabled

# Helper function to enable/disable specific bones by name
func set_bone_mask_by_name(bone_name: String, p_enabled: bool) -> void:
	if not skeleton:
		return
	var bone_idx = skeleton.find_bone(bone_name)
	if bone_idx != -1:
		set_bone_mask(bone_idx, p_enabled)

# Helper function to sample the current bone poses
func sample_bone_poses() -> Array[Transform3D]:
	if not skeleton:
		return [] as Array[Transform3D]
	var poses: Array[Transform3D] = []
	poses.resize(skeleton.get_bone_count())
	for i in range(skeleton.get_bone_count()):
		poses[i] = skeleton.get_bone_pose(i)
	return poses

# Helper function to enable a group of bones by name
func enable_bones(bone_names: Array[String]) -> void:
	for bone_name in bone_names:
		set_bone_mask_by_name(bone_name, true)

# Helper function to disable a group of bones by name
func disable_bones(bone_names: Array[String]) -> void:
	for bone_name in bone_names:
		set_bone_mask_by_name(bone_name, false)

func reset_bone_mask() -> void:
	for i in range(bone_mask.size()):
		bone_mask[i] = false

func play_override(p_animation_name: String) -> void:
	active = true
	anim_progess = 0.0
	anim_accumulator = 0.0
	override_animation_name = p_animation_name
