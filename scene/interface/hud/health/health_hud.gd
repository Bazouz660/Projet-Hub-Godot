extends Control

@export var health_bar: ProgressBar
@export var ghost_bar: ProgressBar
@export var animation_player: AnimationPlayer
@export var resources: HumanoidResources
var _is_hide: bool = false

var health_value: float = 0.0
var target_value: float = 0.0
var ghost_value: float = 0.0
var main_tween: Tween
var ghost_tween: Tween

func _ready() -> void:
	#animation_player.play("health_hide")
	_is_hide = true

func _setup():
	resources.health_changed.connect(_on_health_health_changed)
	print("Connected to health_changed")
	resources.health_low.connect(_on_health_health_low)
	resources.health_full.connect(_on_health_health_full)

	health_value = resources.get_current_health() / resources.get_max_health()
	print("Health value: ", health_value)
	ghost_value = health_value
	health_bar.value = health_value
	ghost_bar.value = ghost_value

	print("Done health setup")

func _on_health_health_changed(current_health: float) -> void:

	print("Health changed")

	if _is_hide:
		#animation_player.play("health_show")
		_is_hide = false

	target_value = current_health / resources.get_max_health()

	print("Current health: ", current_health)
	print("Max health: ", resources.get_max_health())
	print("Target value: ", target_value)

	if main_tween and main_tween.is_valid():
		main_tween.kill()
	if ghost_tween and ghost_tween.is_valid():
		ghost_tween.kill()

	main_tween = create_tween()
	main_tween.set_trans(Tween.TRANS_CUBIC)
	main_tween.set_ease(Tween.EASE_OUT)
	main_tween.tween_property(health_bar, "value", target_value, 0.3)
	main_tween.tween_property(self, "health_value", target_value, 0.3)

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

func _on_health_health_low() -> void:
	#animation_player.play("health_low")
	pass

func _on_health_health_full() -> void:
	#animation_player.play("health_full")
	pass

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "health_full":
		animation_player.play("health_hide")
		_is_hide = true
