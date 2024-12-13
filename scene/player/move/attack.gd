extends Move
class_name Attack

@export var COMBO_TIMING = 0.8 # Time at which we can chain the attack
@export var hit_damage = 20 # will be a function of player stats in the future

func on_enter_state():
	humanoid.velocity = Vector3.ZERO

func default_lifecycle(input: InputPackage):
	if works_longer_than(COMBO_TIMING) and has_queued_move:
		has_queued_move = false
		return queued_move
	elif works_longer_than(DURATION):
		input.actions.sort_custom(container.moves_priority_sort)
		return input.actions[0]
	else:
		return "ok"


func update(_input: InputPackage, _delta: float):
	humanoid.model.active_weapon.is_attacking = right_weapon_hurts()

func form_hit_data(weapon: Weapon) -> HitData:
	var hit = HitData.new()
	hit.damage = hit_damage
	hit.hit_move_animation = animation
	hit.is_parryable = is_parryable()
	hit.weapon = humanoid.model.active_weapon
	return hit


func on_exit_state():
	super.on_exit_state()
	humanoid.model.active_weapon.hitbox_ignore_list.clear()
	humanoid.model.active_weapon.is_attacking = false
