extends Node

signal time_changed(time)
signal state_changed(paused)
signal time_scale_changed(scale)

var time_scale: float = 1.0:
	set(value):
		time_scale = value
		time_scale_changed.emit(time_scale)
		time_changed.emit(time)

var time: float = 23.0
var _paused: bool = true

const _SECONDS_PER_HOUR: float = 60.0

const DAY_START = 6
const NIGHT_START = 18

func _ready() -> void:

	await MultiplayerManager.is_host_changed

	if MultiplayerManager.is_host:

		MultiplayerManager.session_active.connect(func():
				time_changed.connect(func(p_time):
					rpc("_peers_sync_time", p_time)))

		MultiplayerManager.player_connected.connect(func(_id):
			rpc("_peers_sync_time", get_time_of_day()))

		time_scale_changed.connect(func(scale): rpc("_peers_sync_time_scale", scale))

@rpc("any_peer", "call_remote", "unreliable")
func _peers_sync_time(p_time: float):
	_set_time(p_time)

@rpc("any_peer", "call_remote", "unreliable")
func _peers_sync_time_scale(p_scale: float):
	time_scale = p_scale

func _set_time(p_time: float):
	time = p_time
	time_changed.emit(time)

func start():
	_paused = false
	state_changed.emit(false)

func pause():
	_paused = true
	state_changed.emit(true)

func reset(p_pause: bool = false):
	if _paused != p_pause:
		_paused = p_pause
		state_changed.emit(_paused)
	_set_time(DAY_START)

func _process(delta: float) -> void:
	if _paused:
		return
	time += delta * time_scale / _SECONDS_PER_HOUR
	time = _loop_value(time, 24)

func get_time_of_day() -> float:
	return _loop_value(time, 24)

func get_time_of_day_str() -> String:
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
	return integer_str + ":" + decimals_str

func _loop_value(value: float, mod: int) -> float:
	var decimals = fposmod(value, 1)
	value = int(value) % mod
	return value + decimals

func set_time_of_day(hour: float) -> void:
	_set_time(hour)