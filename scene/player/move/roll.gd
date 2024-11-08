extends Move
class_name Roll

var roll_duration : float = 0.833
var SPEED : float = 12
var roll_direction : Vector3 = Vector3(0.0, 0.0, 0.0)
var roll_direction_defined : bool = false

func _ready():
	stamina_required = 10.0
	animation = "roll"

func on_enter_state():
	player.stamina.use_stamina(stamina_required)
	roll_direction_defined = false

func check_relevance(input) -> String:
	input.actions.sort_custom(moves_priority_sort)
	if works_less_than(roll_duration):
		return "ok"
	return input.actions[0]

func update(input : InputPackage, _delta : float):

	if not roll_direction_defined:
		roll_direction = Vector3(input.direction.x, 0, input.direction.y).rotated(Vector3.UP, input.camera_rotation.y)
		roll_direction_defined = true
		player.rotation.y = atan2(roll_direction.x, roll_direction.z)

	player.velocity = velocity_by_input(input)

func velocity_by_input(_input : InputPackage) -> Vector3:
	var y = player.velocity.y
	var velocity = lerp(player.velocity, roll_direction * SPEED, 0.1)
	velocity.y = y
	return velocity
