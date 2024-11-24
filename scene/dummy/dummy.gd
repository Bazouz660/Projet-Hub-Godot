extends Player
class_name Dummy

func _enter_tree():
	pass

func _ready():
	presentation.accept_model(model)
	presentation.register_sounds(model.sound_manager)
	model.animator.play("ready_idle")

func _physics_process(delta):
	var input = input_gatherer.create_empty_input()
	model.update(input, delta)
	input.queue_free()

func is_grounded() -> bool:
	return grounded or is_on_floor()
	
func is_in_water() -> bool:
	return global_position.y + height <= WATER_LEVEL
	
@rpc("any_peer", "call_remote", "reliable")
func rpc_set_position(pos):
	position = pos
	velocity = Vector3.ZERO
