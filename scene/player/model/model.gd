extends Node3D
class_name PlayerModel

@onready var DEFAULT_GRAVITY : float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var player = $".." as Player
@onready var skeleton = %GeneralSkeleton
@onready var animator = $AnimationPlayer

const STEP_INTERPOLATION_SPEED = 30.0

var current_move : Move = null
var current_state : String = ""

@export var sync_state : String :
	get:
		return current_state
	set(value):
		current_state = value
		if moves == null:
			return
		if moves.has(value):
			switch_to(value)

# Add moves to the model
var moves

func _ready():

	moves = {
		"idle" : $Idle,
		"run" : $Run,
		"sprint" : $Sprint,
		"roll" : $Roll,
	}

	current_move = moves["idle"]
	for move in moves.values():
		move.player = player

func update(input : InputPackage, delta : float):
	var relevance = current_move.check_relevance(input)
	if relevance != "ok" and player.stamina.has_stamina(moves[relevance].stamina_required):
		switch_to(relevance)
	if current_move.affected_by_gravity:
		apply_gravity(delta)
	current_move.update(input, delta)
	raycast(delta)
	player.move_and_slide()

func switch_to(state : String):
	current_state = state
	current_move.on_exit_state()
	current_move = moves[state]
	current_move.on_enter_state()
	current_move.mark_enter_state()
	animator.play(current_move.animation)
	
func apply_gravity(delta : float, gravity : float = DEFAULT_GRAVITY):
	if not player.is_grounded():
		player.velocity.y -= gravity * delta
		
func raycast(delta : float):
	player.step_cast.global_position.x = player.global_position.x + player.velocity.x * delta
	player.step_cast.global_position.z = player.global_position.z + player.velocity.z * delta

	var query = PhysicsShapeQueryParameters3D.new()
	query.exclude = [player]
	query.shape = player.step_cast.shape
	query.transform = player.step_cast.global_transform
	var result = get_world_3d().direct_space_state.intersect_shape(query, 1)
	if !result:
		player.step_cast.force_shapecast_update()
	
	if player.step_cast.is_colliding() and absf(player.velocity.y) <= 0.0001 and !result:
		var collision_point = player.step_cast.get_collision_point(0)
		player.global_position.y = lerp(player.global_position.y, collision_point.y, delta * STEP_INTERPOLATION_SPEED)
		player.velocity.y = 0.0
		player.grounded = true
	else:
		player.grounded = false
