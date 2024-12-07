extends Node
class_name MovesDataRepository

@onready var move_database = $MoveDatabase


func get_root_delta_pos(animation: String, progress: float, delta: float) -> Vector3:
	var data = move_database.get_animation(animation) as Animation
	var track = data.find_track("MoveDatabase:root_position", Animation.TYPE_VALUE)

	# Handle looping animations
	if data.loop_mode == Animation.LOOP_LINEAR:
		var previous_time = progress - delta
		var current_time = progress

		# Normalize both times to be within animation length
		current_time = fmod(current_time, data.length)
		if current_time < 0:
			current_time += data.length

		previous_time = fmod(previous_time, data.length)
		if previous_time < 0:
			previous_time += data.length

		# Get positions at both times
		var previous_pos = data.value_track_interpolate(track, previous_time)
		var current_pos = data.value_track_interpolate(track, current_time)

		# Special handling for loop transition
		if previous_time > current_time:
			# Animation looped, get the position at the end and beginning
			var end_pos = data.value_track_interpolate(track, data.length)
			var start_pos = data.value_track_interpolate(track, 0)
			# Calculate the total delta through the loop point
			return (end_pos - previous_pos) + (current_pos - start_pos)

		return current_pos - previous_pos
	else:
		# Non-looping animation - original behavior
		var previous_pos = data.value_track_interpolate(track, progress - delta)
		var current_pos = data.value_track_interpolate(track, progress)
		return current_pos - previous_pos


func get_transitions_to_queued(animation: String, timecode: float) -> bool:
	var data = move_database.get_animation(animation)
	var track = data.find_track("MoveDatabase:transitions_to_queued", Animation.TYPE_VALUE)
	return move_database.get_boolean_value(animation, track, timecode)

func get_accepts_queueing(animation: String, timecode: float) -> bool:
	var data = move_database.get_animation(animation)
	var track = data.find_track("MoveDatabase:accepts_queueing", Animation.TYPE_VALUE)
	return move_database.get_boolean_value(animation, track, timecode)

func get_vulnerable(animation: String, timecode: float) -> bool:
	var data = move_database.get_animation(animation)
	var track = data.find_track("MoveDatabase:is_vulnerable", Animation.TYPE_VALUE)
	return move_database.get_boolean_value(animation, track, timecode)

func get_interruptable(animation: String, timecode: float) -> bool:
	var data = move_database.get_animation(animation)
	var track = data.find_track("MoveDatabase:is_interruptable", Animation.TYPE_VALUE)
	return move_database.get_boolean_value(animation, track, timecode)

func get_parryable(animation: String, timecode: float) -> bool:
	var data = move_database.get_animation(animation)
	var track = data.find_track("MoveDatabase:is_parryable", Animation.TYPE_VALUE)
	return move_database.get_boolean_value(animation, track, timecode)

func get_duration(animation: String) -> float:
	return move_database.get_animation(animation).length

func get_right_weapon_hurts(animation: String, timecode: float) -> bool:
	var data = move_database.get_animation(animation)
	var track = data.find_track("MoveDatabase:right_hand_weapon_hurts", Animation.TYPE_VALUE)
	return move_database.get_boolean_value(animation, track, timecode)

func get_tracks_input_vector(animation: String, timecode: float) -> bool:
	var data = move_database.get_animation(animation)
	var track = data.find_track("MoveDatabase:tracks_input_vector", Animation.TYPE_VALUE)
	return move_database.get_boolean_value(animation, track, timecode)
