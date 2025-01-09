extends Player
class_name Dummy

@onready var health_bar := $HealthBar as Control
var out_of_range := false

func _enter_tree():
	pass

func _ready():
	presentation.accept_model(model)
	presentation.register_sounds(model.sound_manager)

func _physics_process(delta):
	var input = input_gatherer.create_empty_input()
	model.update(input, delta)
	input.queue_free()

	var p_camera := get_viewport().get_camera_3d()
	var screen_pos = p_camera.unproject_position($HealthBarTarget.global_position)
	health_bar.global_position = screen_pos - (health_bar.size / 2)

	var active_player = MultiplayerManager.active_player as Player
	var distance_to_player = global_position.distance_to(active_player.global_position)
	var max_distance = 10
	# if the distance is greater than the max distance, use a tween to modulate the alpha of the health bar
	if distance_to_player > max_distance and !out_of_range:
		out_of_range = true
		var tween = create_tween()
		tween.tween_property(health_bar, "modulate:a", 0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	elif distance_to_player <= max_distance and out_of_range:
		out_of_range = false
		var tween = create_tween()
		tween.tween_property(health_bar, "modulate:a", 1, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func is_grounded() -> bool:
	return grounded or is_on_floor()

func is_in_water() -> bool:
	return global_position.y + height <= WATER_LEVEL

@rpc("any_peer", "call_remote", "reliable")
func rpc_set_position(pos):
	position = pos
	velocity = Vector3.ZERO
