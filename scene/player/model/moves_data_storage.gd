@tool
extends AnimationPlayer

@export var root_position: Vector3
@export var transitions_to_queued: bool
@export var accepts_queueing: bool
@export var is_parryable: bool
@export var is_vulnerable: bool
@export var is_interruptable: bool
@export var is_grabable: bool
@export var right_hand_weapon_hurts: bool
@export var tracks_input_vector: bool

@export var add_tracks: bool = false:
	set(value):
		add_tracks = value
		if value:
			_init_tracks()

@export var clear_tracks: bool = false:
	set(value):
		clear_tracks = value
		if value:
			_clear_tracks()

@export var add_single_track: bool = false:
	set(value):
		add_single_track = value
		if value:
			for anim_name in get_animation_list():
				_add_track(anim_name, "tracks_input_vector")

func _init_tracks():
	for anim_name in get_animation_list():
		_add_track(anim_name, "root_position", Vector3(0, 0, 0), Animation.UPDATE_CONTINUOUS)
		_add_track(anim_name, "transitions_to_queued")
		_add_track(anim_name, "accepts_queueing")
		_add_track(anim_name, "is_parryable")
		_add_track(anim_name, "is_vulnerable")
		_add_track(anim_name, "is_interruptable")
		_add_track(anim_name, "is_grabable")
		_add_track(anim_name, "right_hand_weapon_hurts")
		_add_track(anim_name, "tracks_input_vector")

func _clear_tracks():
	for anim_name in get_animation_list():
		var anim = get_animation(anim_name)
		for i in range(anim.get_track_count()):
			anim.remove_track(i)
			i -= 1

func _add_track(animation: String, track_name: String, default_key: Variant = false, update_mode: Animation.UpdateMode = Animation.UPDATE_DISCRETE):
	var anim = get_animation(animation)
	anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(anim.get_track_count() - 1, "MoveDatabase:" + track_name)
	anim.value_track_set_update_mode(anim.get_track_count() - 1, update_mode)
	# add a default keyframe at 0
	anim.track_insert_key(anim.get_track_count() - 1, 0.0, default_key, false)


func get_boolean_value(animation: String, track: int, timecode: float) -> bool:
	var data = get_animation(animation)
	return data.value_track_interpolate(track, timecode)
