extends Node
class_name HumanoidResources

signal stamina_changed(current_stamina: float)
signal stamina_low
signal stamina_full
signal stamina_regeneration_started
signal stamina_regeneration_stopped

signal health_changed(current_health: float)
signal health_low
signal health_full

@export var god_mode: bool = false

@export var health: float = 100:
	set(value):
		health = value
		if health >= max_health:
			health = max_health
			health_full.emit()
		if health <= 0:
			health = 0
			health_low.emit()
			model.current_move.try_force_move.rpc("death")
		print("set health: ", health)

@export var max_health: float = 100

@export var stamina: float = 100:
	set(value):
		stamina = value
		if stamina >= max_stamina:
			stamina = max_stamina
			stamina_full.emit()
		if stamina <= 0:
			stamina = 0
			stamina_low.emit()
		stamina_changed.emit(stamina)

@export var max_stamina: float = 100
@export var stamina_regeneration_rate: float = 10 # per sec because we will multiply it by delta
@export var regeneration_enabled: bool = true

@onready var model = $".." as HumanoidModel

var stamina_regeneration_timer: float = 0.0
var is_stamina_regenerating: bool = true

func _ready():
	stamina = max_stamina
	health = max_health

func lose_health(amount: float):
	if not god_mode:
		health = health - amount
		_on_health_changed(health)

func gain_health(amount: float):
	health = health + amount
	_on_health_changed(health)

func lose_stamina(amount: float):
	if amount <= 0:
		return
	stamina = stamina - amount
	stop_regeneration()

func get_current_stamina() -> float:
	return stamina

func get_max_stamina() -> float:
	return max_stamina

func get_current_health() -> float:
	return health

func get_max_health() -> float:
	return max_health

func gain_stamina(amount: float):
	stamina = stamina + amount

func update(delta: float):
	if not regeneration_enabled:
		return
	if not is_stamina_regenerating:
		stamina_regeneration_timer += delta
		if stamina_regeneration_timer >= 1.0:
			start_stamina_regeneration()
	elif stamina < max_stamina:
		gain_stamina(stamina_regeneration_rate * delta)

func stop_regeneration() -> void:
	is_stamina_regenerating = false
	stamina_regeneration_timer = 0.0
	stamina_regeneration_stopped.emit()

func start_stamina_regeneration() -> void:
	is_stamina_regenerating = true
	stamina_regeneration_timer = 0.0
	stamina_regeneration_started.emit()

func set_regeneration_enabled(enabled: bool) -> void:
	regeneration_enabled = enabled
	if !enabled:
		stop_regeneration()

func pay_resource_cost(move: Move):
	lose_stamina(move.enter_stamina_cost)

func can_be_paid(move: Move) -> bool:
	if stamina >= move.enter_stamina_cost:
		return true
	stamina_low.emit()
	return false

func _on_health_changed(current_health: float):
	_rpc_set_health.rpc(current_health)

@rpc("any_peer", "call_local", "reliable")
func _rpc_set_health(p_health: float):
	self.health = p_health
	health_changed.emit(health)