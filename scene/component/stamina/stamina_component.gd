extends Node
class_name StaminaComponent

@export var max_stamina: float = 100.0
@export var stamina_regeneration_speed: float = 20.0
@export var regeneration_enabled: bool = true

var current_stamina: float = 0.0
var regeneration_timer: float = 0.0
var is_regenerating: bool = true

signal stamina_changed(current_stamina: float)
signal regeneration_started
signal regeneration_stopped
signal stamina_low
signal stamina_full

func _ready() -> void:
	current_stamina = max_stamina
	stamina_changed.emit(current_stamina)
	stamina_full.emit()

func _process(delta: float) -> void:
	if !regeneration_enabled:
		return
		
	if !is_regenerating:
		regeneration_timer += delta
		if regeneration_timer >= 1.0:
			start_regeneration()
	elif current_stamina < max_stamina:
		add_stamina(stamina_regeneration_speed * delta)
		stamina_changed.emit(current_stamina)

func has_stamina(amount: float) -> bool:
	if current_stamina < amount:
		stamina_low.emit()
		return false
	return true

func use_stamina(amount: float) -> void:
	if !has_stamina(amount):
		return
	current_stamina = max(0, current_stamina - amount)
	stamina_changed.emit(current_stamina)
	stop_regeneration()

func add_stamina(amount: float) -> void:
	current_stamina = min(current_stamina + amount, max_stamina)
	stamina_changed.emit(current_stamina)
	if current_stamina >= max_stamina:
		stamina_full.emit()

func stop_regeneration() -> void:
	is_regenerating = false
	regeneration_timer = 0.0
	regeneration_stopped.emit()

func start_regeneration() -> void:
	is_regenerating = true
	regeneration_timer = 0.0
	regeneration_started.emit()

func set_regeneration_enabled(enabled: bool) -> void:
	regeneration_enabled = enabled
	if !enabled:
		stop_regeneration()
