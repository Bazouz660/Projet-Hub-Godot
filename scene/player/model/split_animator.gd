extends Node
class_name SplitAnimator

@export var torso_animator: AnimationPlayer
@export var legs_animator: AnimationPlayer

@export var model: HumanoidModel
@export var skeleton: Skeleton3D # MixamoSkeleton
var full_body_mode: bool = true

# This script is used to play animations for the model, either full body or split.
# When split, it plays animations for torso and legs separately.
# It does so by using two AnimationPlayer nodes, one for torso and one for legs.
# When playing a split animation, it disables tracks for specific bones in the skeleton.
# When playing a full body animation, it enables all tracks and uses the torso AnimationPlayer.

var synchronization_delta = 0.01

func toggle_tracks(animation_name: String, enable: bool, torso_or_legs: String):
	var animation = legs_animator.get_animation(animation_name)
	if animation:
		var bones = []
		if torso_or_legs == "torso":
			bones = model.skeleton.torso_bones
		elif torso_or_legs == "legs":
			bones = model.skeleton.legs_bones
		else:
			#print("ERROR: Invalid argument for torso_or_legs: ", torso_or_legs)
			return
		for bone in bones:
			var path = skeleton.name + ":" + bone
			#print("Toggling track for: ", path)
			_toggle_track(animation, enable, path, Animation.TYPE_POSITION_3D)
			_toggle_track(animation, enable, path, Animation.TYPE_ROTATION_3D)
			_toggle_track(animation, enable, path, Animation.TYPE_SCALE_3D)

	else:
		print("ERROR: Animation not found: ", animation_name)

func _toggle_track(animation: Animation, enable: bool, path: String, type: Animation.TrackType):
	var track = animation.find_track(path, type)
	if track == -1:
		#print("ERROR: Track not found: ", path)
		return
	if enable:
		animation.track_set_enabled(track, true)
	else:
		animation.track_set_enabled(track, false)


func play(move: Move):
	if move is not TorsoPartialMove and full_body_mode:
		clear_torso_animation()

	if move.reverse_animation:
		torso_animator.play_backwards(move.animation)
	else:
		torso_animator.play(move.animation)

func update_legs_animation():
	# disable torso tracks for leg animation
	toggle_tracks(model.legs.current_legs_move.animation, false, "torso")
	# enable leg tracks for leg animation
	toggle_tracks(model.legs.current_legs_move.animation, true, "legs")

	# disable leg tracks for torso animation
	toggle_tracks(model.current_move.animation, false, "legs")
	# enable torso tracks for torso animation
	toggle_tracks(model.current_move.animation, true, "torso")
	legs_animator.play(model.legs.current_legs_move.animation)
	full_body_mode = false

func clear_torso_animation():
	toggle_tracks(model.current_move.animation, true, "torso")
	toggle_tracks(model.current_move.animation, true, "legs")
	toggle_tracks(model.legs.current_legs_move.animation, true, "torso")
	toggle_tracks(model.legs.current_legs_move.animation, true, "legs")
	legs_animator.stop()
	full_body_mode = true
