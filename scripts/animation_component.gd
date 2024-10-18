extends Node
class_name AnimationComponent

signal entered

@export_group("Options")
@export var from_center: bool = true
@export var parallel_animations: bool = true
var properties: Array = [
	"scale",
	"position",
	"rotation",
	"size",
	"self_modulate"
]

@export_group("Hover settings")
@export var hover_resource: AnimationSettings = AnimationSettings.new()

@export_group("Down settings")
@export var down_resource: AnimationSettings = AnimationSettings.new()

@export_group("Enter settings")
@export var enter_resource: AnimationSettings = AnimationSettings.new()
@export var enter_animation: bool = true
@export var restart_on_visibility_changed : bool = true
@export var wait_for : AnimationComponent

var default_resource: AnimationSettings = AnimationSettings.new()

var target: Control
var current_state: String = "default"
var current_tween: Tween
var initial_values: Dictionary
var is_entered : bool = !enter_animation

func _ready():
	target = get_parent()
	call_deferred("setup")

func connect_signals():
	target.mouse_entered.connect(on_mouse_entered)
	target.mouse_exited.connect(on_mouse_exited)
	target.visibility_changed.connect(on_visibility_changed)
	if target is BaseButton:
		(target as BaseButton).button_down.connect(on_button_down)
		(target as BaseButton).button_up.connect(on_button_up)
	target.resized.connect(update_pivot)

func setup():
	update_pivot()
	connect_signals()
	if enter_animation:
		call_deferred("start_enter_animation")

func update_pivot():
	if from_center:
		target.pivot_offset = target.size / 2
	else:
		target.pivot_offset = Vector2.ZERO

func apply_animation(state: String):
	if current_tween and current_tween.is_valid():
		current_tween.kill()  # Stop any ongoing animation

	var resource: AnimationSettings
	match state:
		"default":
			resource = default_resource
		"hover":
			resource = hover_resource
		"down":
			resource = down_resource
		"enter":
			resource = enter_resource

	current_tween = create_tween()
	current_tween.pause()
	current_tween.set_parallel(parallel_animations)

	for property in properties:
		var start_value = target.get(property)
		var target_value = get_target_value(property, resource)
		
		if state == "enter":
			target.set(property, target_value)
			var temp = start_value
			start_value = target_value
			target_value = temp

		current_tween.tween_property(target, property, target_value, resource.time) \
			.from(start_value) \
			.set_trans(resource.transition) \
			.set_ease(resource.easing) \
			.set_delay(resource.delay)

	current_state = state

	if state == "enter":
		if wait_for and !wait_for.is_entered:
			await wait_for.entered
			current_tween.play()
		else:
			current_tween.play()
		await current_tween.finished
		_on_enter_animation_finished()
	else:
		current_tween.play()

func get_target_value(property: String, resource: AnimationSettings):
	var base_value = target.get(property)
	match property:
		"scale":
			return resource.scale if resource.scale != Vector2.ZERO else base_value
		"position":
			return base_value + resource.position
		"rotation":
			return base_value + deg_to_rad(resource.rotation)
		"size":
			return base_value + resource.size
		"self_modulate":
			return resource.modulate if resource.modulate.a > 0 else base_value
	return base_value

func on_mouse_entered():
	if current_state != "down":
		apply_animation("hover")

func on_mouse_exited():
	if current_state != "down":
		apply_animation("default")
		
func on_visibility_changed():
	if restart_on_visibility_changed and target.is_visible_in_tree() and enter_animation:
		is_entered = false
		call_deferred("start_enter_animation")

func on_button_down():
	apply_animation("down")

func on_button_up():
	if target.is_hovered():
		apply_animation("hover")
	else:
		apply_animation("default")

func get_current_properties() -> Dictionary:
	var properties_dict = {}
	for property in properties:
		properties_dict[property] = target.get(property)
	return properties_dict

func start_enter_animation():
	apply_animation("enter")

func _on_enter_animation_finished():
	current_state = "default"
	is_entered = true
	entered.emit()
