@tool
extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var label = $Label

signal time_changed(time)

@export var time_scale : float = 1.0:
	set(value):
		time_scale = value
		if not is_node_ready():
			await ready
		if day_duration and night_duration:
			_set_day_duration()
			_set_night_duration()
			
@export var day_duration: float = 2.0:  # Total real-time duration of the day cycle in seconds
	set(value):
		day_duration = value
		if not is_node_ready():
			await ready
		_set_day_duration()


@export var night_duration: float = 2.0:  # Total real-time duration of the night cycle in seconds
	set(value):
		night_duration = value
		if not is_node_ready():
			await ready
		_set_night_duration()


@export_range(0.0, 24.0) var time : float = 6.0:
	set(value):
		time = value
		if not is_node_ready():
			await ready
		set_time_of_day(time)
	get():
		return time

const DAY_START = 6
const NIGHT_START = 18

func _ready() -> void:
	animation_player.play("Day")
	animation_player.animation_finished.connect(_on_animation_finished)

	if MultiplayerManager.is_host:
		
		MultiplayerManager.session_active.connect(func():
				time_changed.connect(func(time):
					rpc("_peers_sync_time", time)))

		MultiplayerManager.player_connected.connect(func(_id):
			rpc("_peers_sync_time", get_time_of_day()))
	
func _set_day_duration():
	var raw_day_duration = animation_player.get_animation("Day").length
	_set_speed_scale("Day", day_duration)

func _set_night_duration():
	var raw_night_duration = animation_player.get_animation("Night").length
	_set_speed_scale("Night", night_duration)
	
func _set_speed_scale(anim : String, duration : float):
	animation_player.speed_scale = animation_player.get_animation(anim).length / (duration * time_scale)

func _on_animation_finished(anim_name: String) -> void:
	if not is_node_ready():
		await ready

	if anim_name == "Day":
		animation_player.play("Night")
		_set_speed_scale("Night", night_duration)
	elif anim_name == "Night":
		animation_player.play("Day")
		_set_speed_scale("Day", day_duration)
		
func get_time_of_day() -> float:
	var _time : float = 0.0
	var day_hours = _get_day_hours()
	var night_hours = _get_night_hours()
	
	if animation_player.current_animation == "Day":
		var length = animation_player.current_animation_length
		var anim_position = animation_player.current_animation_position
		var progression = anim_position / length
		_time = DAY_START + (progression * day_hours)
	elif animation_player.current_animation == "Night":
		var length = animation_player.current_animation_length
		var anim_position = animation_player.current_animation_position
		var progression = anim_position / length
		_time = NIGHT_START + (progression * night_hours)
		
	return _loop_value(_time, 24)
	
func _get_day_hours():
	var total_duration = (day_duration + night_duration)
	var day_ratio = day_duration / total_duration
	return day_ratio * 24.0
	
func _get_night_hours():
	var total_duration = (day_duration + night_duration)
	var night_ratio = night_duration / total_duration
	return night_ratio * 24.0

func _loop_value(value : float, mod : int) -> float:
	var decimals = fposmod(value, 1)
	value = int(value) % mod
	return value + decimals
	
func _process(_delta):
	var time_of_day = get_time_of_day()
	var decimals = fposmod(time_of_day, 1)
	decimals *= 60
	var integer = int(time_of_day)
	var integer_str = str(integer)
	if integer < 10:
		integer_str = "0" + integer_str
	var decimals_str = str(int(decimals))
	if decimals < 10:
		decimals_str = "0" + decimals_str
	label.text = "Time of day: " + integer_str + ":" + decimals_str

@rpc("any_peer", "call_remote", "unreliable")
func _peers_sync_time(p_time : float):
	set_time_of_day(p_time)

func set_time_of_day(hour: float) -> void:
	hour = _loop_value(hour, 24)
	
	if hour >= NIGHT_START or hour < DAY_START:
		var normalized_hour = (hour - NIGHT_START) / (24.0 - NIGHT_START + DAY_START)
		var raw_night_duration = animation_player.get_animation("Night").length
		animation_player.play("Night")
		_set_speed_scale("Night", night_duration)
		var seek_value = normalized_hour * raw_night_duration
		seek_value = fmod(seek_value, raw_night_duration)
		if seek_value < 0.0:
			seek_value = (raw_night_duration + seek_value)
		animation_player.seek(seek_value, true)
	else:
		var normalized_hour = (hour - DAY_START) / (NIGHT_START - DAY_START)
		var raw_day_duration = animation_player.get_animation("Day").length
		animation_player.play("Day")
		_set_speed_scale("Day", night_duration)
		var seek_value = normalized_hour * raw_day_duration
		seek_value = fmod(seek_value, raw_day_duration)
		if seek_value < 0.0:
			seek_value = (raw_day_duration + seek_value)
		animation_player.seek(seek_value, true)
		
	time_changed.emit(hour)
