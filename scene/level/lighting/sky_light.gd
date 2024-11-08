@tool
extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

const DAY_START = 6
const NIGHT_START = 18

const _SECONDS_PER_HOUR : float = 60.0

func _ready() -> void:
	
	if !TimeManager.is_node_ready():
		print("Waiting for time manager")
		await TimeManager.ready
	
	animation_player.play("Day")
	animation_player.animation_finished.connect(_on_animation_finished)

	if Engine.is_editor_hint():
		return
		
	TimeManager.time_changed.connect(set_time_of_day)
	TimeManager.state_changed.connect(func(_paused): set_time_of_day(TimeManager.get_time_of_day()))
	TimeManager.state_changed.connect(func(paused): if paused: animation_player.pause() else: animation_player.play())
	TimeManager.time_scale_changed.connect(func(p_scale): animation_player.speed_scale = p_scale / _SECONDS_PER_HOUR)
	
	set_time_of_day(TimeManager.get_time_of_day())
	animation_player.speed_scale = TimeManager.time_scale / _SECONDS_PER_HOUR
	

func _on_animation_finished(anim_name: String) -> void:
	if not is_node_ready():
		await ready

	if anim_name == "Day":
		animation_player.play("Night")
	elif anim_name == "Night":
		animation_player.play("Day")

func _loop_value(value : float, mod : int) -> float:
	var decimals = fposmod(value, 1)
	value = int(value) % mod
	return value + decimals
	
func set_time_of_day(hour: float) -> void:
	hour = _loop_value(hour, 24)
		
	if hour >= NIGHT_START or hour < DAY_START:
		var normalized_hour = (hour - NIGHT_START) / (24.0 - NIGHT_START + DAY_START)
		var raw_night_duration = animation_player.get_animation("Night").length
		animation_player.play("Night")
		var seek_value = normalized_hour * raw_night_duration
		seek_value = fmod(seek_value, raw_night_duration)
		if seek_value < 0.0:
			seek_value = (raw_night_duration + seek_value)
		animation_player.seek(seek_value, true)
	else:
		var normalized_hour = (hour - DAY_START) / (NIGHT_START - DAY_START)
		var raw_day_duration = animation_player.get_animation("Day").length
		animation_player.play("Day")
		var seek_value = normalized_hour * raw_day_duration
		seek_value = fmod(seek_value, raw_day_duration)
		if seek_value < 0.0:
			seek_value = (raw_day_duration + seek_value)
		animation_player.seek(seek_value, true)
