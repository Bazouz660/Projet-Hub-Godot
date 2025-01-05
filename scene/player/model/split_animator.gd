extends Node
class_name SplitAnimator

@export var animation_player: AnimationPlayer

@export var model: HumanoidModel
@export var skeleton: Skeleton3D # MixamoSkeleton
var full_body_mode: bool = true
@onready var animationLayer: AnimationLayerModifier3D = %AnimationLayerModifier3D

# This script is used to play animations for the model, either full body or split.
# When split, it plays animations for torso and legs separately.
# It does so by using two AnimationPlayer nodes, one for torso and one for legs.
# When playing a split animation, it disables tracks for specific bones in the skeleton.
# When playing a full body animation, it enables all tracks and uses the torso AnimationPlayer.

var synchronization_delta = 0.01


func play(move: Move):
	if move.reverse_animation:
		animation_player.play_backwards(move.animation)
	else:
		animation_player.play(move.animation)

func update_legs_animation():
	animationLayer.play_override(model.legs.current_legs_move.animation)
	full_body_mode = false

func clear_torso_animation():
	animationLayer.active = false
	full_body_mode = true
