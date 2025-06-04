# filepath: d:\Github\Projet-Hub-Godot\scene\player\model\split_animator.gd
extends Node
class_name SplitAnimator

@export var layered_animation_system: LayeredAnimationSystem

@export var model: HumanoidModel
@export var skeleton: Skeleton3D # MixamoSkeleton
var full_body_mode: bool = true

@export var animation_library: String = ""

# Track current animations to prevent unnecessary resets
var current_upper_body_animation: String = ""
var current_lower_body_animation: String = ""

# This script is used to play animations for the model, either full body or split.
# When split, it plays animations for torso and legs separately.
# It does so by using two AnimationPlayer nodes, one for torso and one for legs.
# When playing a split animation, it disables tracks for specific bones in the skeleton.
# When playing a full body animation, it enables all tracks and uses the torso AnimationPlayer.

var synchronization_delta = 0.01
var torso_bones: Array[String] = []
var legs_bones: Array[String] = []

func _ready() -> void:
	torso_bones = skeleton.torso_bones
	legs_bones = skeleton.legs_bones

func toggle_full_body_mode(enabled: bool) -> void:
	if enabled:
		layered_animation_system.set_layer_weight("LowerBody", 0.0)
		# Clear lower body animation tracker when switching to full body
		current_lower_body_animation = ""
	else:
		layered_animation_system.set_layer_weight("LowerBody", 1.0)
	# Only reset timeline when switching to full body mode
	if enabled:
		layered_animation_system.reset_layer_timeline("LowerBody")
	full_body_mode = enabled

func _get_full_animation_name(animation: String) -> String:
	if animation_library == "":
		return animation
	return animation_library + "/" + animation


func play(move: Move):
	var full_animation_name = _get_full_animation_name(move.animation)

	# Use the new flexible animation system with safe defaults
	if move.reverse_animation:
		layered_animation_system.layer_play_safe("UpperBody", full_animation_name, true)
	else:
		layered_animation_system.layer_play_safe("UpperBody", full_animation_name, false)

	# Update the current animation tracker
	current_upper_body_animation = full_animation_name


func update_legs_animation():
	var full_animation_name = _get_full_animation_name(model.legs.current_legs_move.animation)

	# Only update if we're switching to a different animation
	if current_lower_body_animation == full_animation_name:
		return

	toggle_full_body_mode(false)
	# Use safe animation play method
	layered_animation_system.layer_play_safe("LowerBody", full_animation_name, false)

	# Update the current animation tracker
	current_lower_body_animation = full_animation_name


func clear_torso_animation():
	toggle_full_body_mode(true)
	# Clear the upper body animation tracker since we're switching to full body
	current_upper_body_animation = ""


func get_root_motion_rotation_accumulator() -> Quaternion:
	return layered_animation_system.animation_tree.get_root_motion_rotation_accumulator()


func get_root_motion_position() -> Vector3:
	return layered_animation_system.animation_tree.get_root_motion_position()


func toggle_bone(animation_player: AnimationPlayer, bone_name: String, enabled: bool) -> void:
	for animation_name in animation_player.get_animation_list():
		var animation = animation_player.get_animation(animation_name)
		if animation == null:
			continue

		var track_count = animation.get_track_count()
		for i in range(track_count):
			var track_path := animation.track_get_path(i) as String
			if track_path.contains(bone_name):
				if enabled:
					animation.track_set_enabled(i, true)
				else:
					animation.track_set_enabled(i, false)

# Root motion debugging and advanced controls
func play_with_smooth_transition(move: Move, transition_time: float = 0.3):
	"""Play animation with smooth transition to prevent root motion jumps"""
	var animation_name = _get_full_animation_name(move.animation)

	if move.reverse_animation:
		# For backwards, use safe play since transition doesn't support backwards yet
		layered_animation_system.layer_play_safe("UpperBody", animation_name, true)
	else:
		# Use smooth transition for forward animations
		layered_animation_system.transition_to_animation("UpperBody", animation_name, transition_time)

	# Update tracker
	current_upper_body_animation = animation_name

func debug_animation_state():
	"""Debug current animation state"""
	print("=== Split Animator Debug ===")
	print("Full Body Mode: %s" % full_body_mode)
	print("Tracked Upper Body Animation: %s" % current_upper_body_animation)
	print("Tracked Lower Body Animation: %s" % current_lower_body_animation)
	print("Current Upper Body Weight: %.2f" % layered_animation_system.get_layer_weight("UpperBody"))
	print("Current Lower Body Weight: %.2f" % layered_animation_system.get_layer_weight("LowerBody"))
	layered_animation_system.debug_print_layer_status()

func get_current_root_motion() -> Vector3:
	"""Get current root motion for debugging"""
	return layered_animation_system.get_current_root_motion()

func reset_root_motion_accumulator():
	"""Reset root motion accumulator to prevent drift"""
	if layered_animation_system.animation_tree:
		# This will be handled by the CharacterBody3D automatically
		pass

# Enhanced animation control methods
func play_force(move: Move):
	"""Force play animation even if it's the same as current"""
	var full_animation_name = _get_full_animation_name(move.animation)

	if move.reverse_animation:
		layered_animation_system.layer_play_force("UpperBody", full_animation_name, true)
	else:
		layered_animation_system.layer_play_force("UpperBody", full_animation_name, false)

	current_upper_body_animation = full_animation_name

func get_current_upper_body_animation() -> String:
	"""Get the currently tracked upper body animation"""
	return current_upper_body_animation

func get_current_lower_body_animation() -> String:
	"""Get the currently tracked lower body animation"""
	return current_lower_body_animation

func is_playing_animation(layer: String, animation: String) -> bool:
	"""Check if the specified animation is currently playing on the layer"""
	var full_animation_name = _get_full_animation_name(animation)

	if layer == "UpperBody":
		return current_upper_body_animation == full_animation_name
	elif layer == "LowerBody":
		return current_lower_body_animation == full_animation_name

	return false

func clear_animation_trackers():
	"""Clear all animation trackers - useful for reset scenarios"""
	current_upper_body_animation = ""
	current_lower_body_animation = ""
