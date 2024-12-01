extends Move
class_name Roll

@export var speed: float = 12

var _roll_direction: Vector3 = Vector3(0.0, 0.0, 0.0)
var _roll_direction_defined: bool = false

func on_enter_state():
	_roll_direction_defined = false

func default_lifecycle(input: InputPackage) -> String:
	input.actions.sort_custom(container.moves_priority_sort)
	if works_less_than(DURATION):
		return "ok"
	return input.actions[0]

func update(input: InputPackage, _delta: float):

	if not _roll_direction_defined:
		_roll_direction = Vector3(input.direction.x, 0, input.direction.y).rotated(Vector3.UP, input.camera_rotation.y)
		_roll_direction_defined = true
		humanoid.rotation.y = atan2(_roll_direction.x, _roll_direction.z)

	#var root_pos = humanoid.model.animator.get_root_motion_position()
	#var current_rotation = humanoid.model.animator.get_root_motion_rotation_accumulator().inverse() * humanoid.get_quaternion()
	#var root_velocity = current_rotation * root_pos / delta
	#var root_rotation = humanoid.model.animator.get_root_motion_rotation()
	#humanoid.set_quaternion(humanoid.get_quaternion() * root_rotation)
	#humanoid.velocity = root_velocity

	humanoid.velocity = velocity_by_input(input)

func velocity_by_input(_input: InputPackage) -> Vector3:
	var y = humanoid.velocity.y
	var velocity = lerp(humanoid.velocity, _roll_direction * speed, 0.1)
	velocity.y = y
	return velocity
