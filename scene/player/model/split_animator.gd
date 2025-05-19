extends Node
class_name SplitAnimator

@export var animation_player: AnimationPlayer

@export var model: HumanoidModel
@export var skeleton: Skeleton3D # MixamoSkeleton
var full_body_mode: bool = true
@onready var animationLayer: AnimationLayerModifier3D = %AnimationLayerModifier3D

@export var animation_library: String = ""

# This script is used to play animations for the model, either full body or split.
# When split, it plays animations for torso and legs separately.
# It does so by using two AnimationPlayer nodes, one for torso and one for legs.
# When playing a split animation, it disables tracks for specific bones in the skeleton.
# When playing a full body animation, it enables all tracks and uses the torso AnimationPlayer.

var synchronization_delta = 0.01

func _get_full_animation_name(animation: String) -> String:
	if animation_library == "":
		return animation
	return animation_library + "/" + animation


func play(move: Move):
	if move.reverse_animation:
		animation_player.play_backwards(_get_full_animation_name(move.animation))
	else:
		animation_player.play(_get_full_animation_name(move.animation))

func update_legs_animation():
	animationLayer.play_override(_get_full_animation_name(model.legs.current_legs_move.animation))
	full_body_mode = false

func clear_torso_animation():
	animationLayer.active = false
	full_body_mode = true

func get_root_motion_rotation_accumulator() -> Quaternion:
	if full_body_mode:
		return animation_player.get_root_motion_rotation_accumulator()

	# Else return the root motion rotation accumulator from the animation layer (Legs)
	return animationLayer.get_root_motion_rotation_accumulator()

func get_root_motion_position() -> Vector3:
	if full_body_mode:
		return animation_player.get_root_motion_position()

	# Else return the root motion position from the animation layer (Legs)
	return animationLayer.get_root_motion_position()