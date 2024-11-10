extends Move
class_name Roll

@export var roll_duration : float = 0.833
@export var speed : float = 12

var _roll_direction : Vector3 = Vector3(0.0, 0.0, 0.0)
var _roll_direction_defined : bool = false

func on_enter_state():
	player.stamina.use_stamina(stamina_required)
	_roll_direction_defined = false

func check_relevance(input) -> String:
	input.actions.sort_custom(moves_priority_sort)
	if works_less_than(roll_duration):
		return "ok"
	return input.actions[0]

func update(input : InputPackage, _delta : float):

	if not _roll_direction_defined:
		_roll_direction = Vector3(input.direction.x, 0, input.direction.y).rotated(Vector3.UP, input.camera_rotation.y)
		_roll_direction_defined = true
		player.rotation.y = atan2(_roll_direction.x, _roll_direction.z)

	player.velocity = velocity_by_input(input)

func velocity_by_input(_input : InputPackage) -> Vector3:
	var y = player.velocity.y
	var velocity = lerp(player.velocity, _roll_direction * speed, 0.1)
	velocity.y = y
	return velocity
