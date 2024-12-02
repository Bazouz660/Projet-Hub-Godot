extends Node3D
class_name HumanoidModel

@onready var active_weapon: Weapon = $GeneralSkeleton/RightHand/WeaponSocket/Sword as Sword

@onready var DEFAULT_GRAVITY: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var humanoid := $".." as CharacterBody3D
@onready var sound_manager := $SoundManager as HumanoidSoundManager
@onready var skeleton := %GeneralSkeleton as Skeleton3D
@onready var animator := $SplitAnimator as SplitAnimator
@onready var combat := $Combat as HumanoidCombat
@onready var moves_node = $States
@onready var moves_data_repository := $MovesDataRepository as MovesDataRepository
@onready var resources := $Resources as HumanoidResources
@onready var moves_container := $States as HumanoidStates
@onready var legs := $Legs as Legs

const STEP_INTERPOLATION_SPEED = 30.0

var current_move: Move = null
var _current_state: String = ""

@export var sync_state: String:
	get:
		return _current_state
	set(value):
		if moves == null:
			return
		if moves.has(value):
			switch_to(value)

# Add moves to the model
var moves: Dictionary

func _ready():
	moves_container.humanoid = humanoid
	moves_container.accept_moves()
	moves = moves_container.moves
	current_move = moves_container.moves["idle"]
	current_move.on_enter_state()
	current_move.mark_enter_state()

	legs.current_legs_move = moves_container.get_move_by_name("idle")
	legs.accept_behaviours()

func update(input: InputPackage, delta: float):
	input = combat.contextualize(input)
	var relevance = current_move.check_relevance(input)

	if relevance != "ok" and resources.can_be_paid(moves[relevance]):
		switch_to(relevance)

	if current_move.affected_by_gravity:
		apply_gravity(delta)

	current_move._update(input, delta)

	raycast(delta)
	humanoid.move_and_slide()

	# Sound
	sound_manager.update(current_move.sound, delta)

func switch_to(state: String):
	print(_current_state, " -> ", state)
	_current_state = state
	current_move.on_exit_state()
	current_move = moves[state]
	current_move.on_enter_state()
	current_move.mark_enter_state()
	resources.pay_resource_cost(current_move)

	animator.play(current_move)

	sound_manager.update_once(current_move.sound)

func apply_gravity(delta: float, gravity: float = DEFAULT_GRAVITY):
	if not humanoid.is_grounded():
		humanoid.velocity.y -= gravity * delta

func raycast(delta: float):
	humanoid.step_cast.global_position.x = humanoid.global_position.x + humanoid.velocity.x * delta
	humanoid.step_cast.global_position.z = humanoid.global_position.z + humanoid.velocity.z * delta

	var query = PhysicsShapeQueryParameters3D.new()
	query.exclude = [humanoid]
	query.shape = humanoid.step_cast.shape
	query.transform = humanoid.step_cast.global_transform
	var result = get_world_3d().direct_space_state.intersect_shape(query, 1)
	if !result:
		humanoid.step_cast.force_shapecast_update()

	if humanoid.step_cast.is_colliding() and absf(humanoid.velocity.y) <= 0.0001 and !result:
		var collision_point = humanoid.step_cast.get_collision_point(0)
		humanoid.global_position.y = lerp(humanoid.global_position.y, collision_point.y, delta * STEP_INTERPOLATION_SPEED)
		humanoid.velocity.y = 0.0
		humanoid.grounded = true
	else:
		humanoid.grounded = false
