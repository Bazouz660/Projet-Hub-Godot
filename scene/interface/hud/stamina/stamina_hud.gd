extends Control

@onready var stamina_bar: TextureProgressBar = $StaminaBar
@onready var ghost_bar: TextureProgressBar = $GhostBar
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@export var stamina: StaminaComponent
var _is_hide: bool = false

var stamina_value: float = 0.0
var target_value: float = 0.0
var ghost_value: float = 0.0
var main_tween: Tween
var ghost_tween: Tween

func _ready() -> void:
	animation_player.play("stamina_hide")
	_is_hide = true

func _setup():
	stamina.stamina_changed.connect(_on_stamina_stamina_changed)
	stamina.stamina_low.connect(_on_stamina_stamina_low)
	stamina.stamina_full.connect(_on_stamina_stamina_full)

	stamina_value = stamina.current_stamina / stamina.max_stamina
	ghost_value = stamina_value
	stamina_bar.value = stamina_value
	ghost_bar.value = ghost_value

func _on_stamina_stamina_changed(current_stamina: float) -> void:
	if _is_hide:
		animation_player.play("stamina_show")
		_is_hide = false

	target_value = current_stamina / stamina.max_stamina
	
	if main_tween and main_tween.is_valid():
		main_tween.kill()
	if ghost_tween and ghost_tween.is_valid():
		ghost_tween.kill()
	
	main_tween = create_tween()
	main_tween.set_trans(Tween.TRANS_CUBIC)
	main_tween.set_ease(Tween.EASE_OUT)
	main_tween.tween_property(stamina_bar, "value", target_value, 0.3)
	main_tween.tween_property(self, "stamina_value", target_value, 0.3)
	
	if target_value < ghost_bar.value:
		ghost_tween = create_tween()
		ghost_tween.set_trans(Tween.TRANS_CUBIC)
		ghost_tween.set_ease(Tween.EASE_OUT)
		ghost_tween.tween_interval(0.5)
		ghost_tween.tween_property(ghost_bar, "value", target_value, 0.6)
		ghost_tween.tween_property(self, "ghost_value", target_value, 0.6)
	else:
		ghost_tween = create_tween()
		ghost_tween.set_trans(Tween.TRANS_CUBIC)
		ghost_tween.set_ease(Tween.EASE_OUT)
		ghost_tween.tween_property(ghost_bar, "value", target_value, 0.3)
		ghost_tween.tween_property(self, "ghost_value", target_value, 0.3)

func _on_stamina_stamina_low() -> void:
	animation_player.play("stamina_low")

func _on_stamina_stamina_full() -> void:
	animation_player.play("stamina_full")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "stamina_full":
		animation_player.play("stamina_hide")
		_is_hide = true
