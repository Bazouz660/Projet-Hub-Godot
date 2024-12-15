extends Node3D

@export var animation_player: AnimationPlayer

func _ready() -> void:

	if !TimeManager.is_node_ready():
		print("Waiting for time manager")
		await TimeManager.ready

	toggle_cycle(true)
	set_time_scale(TimeManager.time_scale)
	set_time_of_day(TimeManager.get_time_of_day())

	if Engine.is_editor_hint():
		return

	TimeManager.time_changed.connect(set_time_of_day)
	TimeManager.time_scale_changed.connect(set_time_scale)
	TimeManager.state_changed.connect(func(p_paused): toggle_cycle(!p_paused))

func _loop_value(value: float, mod: int) -> float:
	var decimals = fposmod(value, 1)
	value = int(value) % mod
	return value + decimals

func set_time_of_day(hour: float) -> void:
	hour = _loop_value(hour, 24)
	animation_player.seek(hour, true)

func set_time_scale(p_scale: float) -> void:
	animation_player.speed_scale = p_scale * _compute_default_time_scale()

func _compute_default_time_scale() -> float:
	# compute the default time scale using the seconds per hour
	return 1.0 / TimeManager._SECONDS_PER_HOUR

func toggle_cycle(toggle: bool) -> void:
	if toggle:
		animation_player.play("day_night_cycle")
	else:
		animation_player.pause()
