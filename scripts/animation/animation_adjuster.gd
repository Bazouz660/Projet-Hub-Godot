@tool
extends AnimationPlayer

@export var skeleton_name: String = "%Skeleton"
@export var hips_bone_name: String = "Hips"

@export var hip_height_adjust: float = 0.0:
	set(value):
		hip_height_adjust = value
		adjust_hip_height()

var _original_keys_height: Array[float] = []

func _ready():
	current_animation_changed.connect(on_current_animation_changed)

func on_current_animation_changed(animation_name: String):
	if animation_name == "":
		return

	# Store the original keys height for the current animation
	var animation := get_animation(animation_name)
	if animation == null:
		return

	_original_keys_height.clear()
	var hip_track_idx := animation.find_track(skeleton_name + ":" + hips_bone_name, Animation.TrackType.TYPE_POSITION_3D)
	if hip_track_idx != -1:
		var key_count := animation.track_get_key_count(hip_track_idx)
		for i in range(key_count):
			var key_value := animation.track_get_key_value(hip_track_idx, i) as Vector3
			_original_keys_height.append(key_value.y)

func adjust_hip_height():
	# Get the current animation
	var animation_name := get_current_animation()
	if animation_name == "":
		print("No current animation")
		return

	var animation := get_animation(animation_name)
	if animation == null:
		print("Animation not found: ", animation_name)
		return

	# Get the hips track
	var hip_track_idx := animation.find_track(skeleton_name + ":" + hips_bone_name, Animation.TrackType.TYPE_POSITION_3D)
	if hip_track_idx == -1:
		return

	# Loop over the keys in the hips track
	var key_count := animation.track_get_key_count(hip_track_idx)
	for i in range(key_count):
		# Get the key time and value
		var key_value := animation.track_get_key_value(hip_track_idx, i) as Vector3

		# Adjust the Y component of the key value
		key_value.y = _original_keys_height[i] + hip_height_adjust

		# Set the new key value
		animation.track_set_key_value(hip_track_idx, i, key_value)
