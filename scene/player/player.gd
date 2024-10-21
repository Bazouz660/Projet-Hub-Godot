extends CharacterBody3D
class_name Player

@onready var input_gatherer = $Input as InputGatherer
@onready var model = $Model as PlayerModel
@onready var presentation = $Presentation
@onready var camera = $Camera/PreventRotationCopy/CameraPivot/Camera3D
@onready var step_cast = $StepCast as ShapeCast3D

var sensitivity = 0.003;
var yaw = 0.0;
var grounded = false;

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _ready():
	GameManager.disable_player_input = false
	presentation.accept_skeleton(model.skeleton)
	model.animator.play("ready_idle")

func _physics_process(delta):
	camera.current = is_multiplayer_authority()
	if not is_multiplayer_authority():
		return
	var input = input_gatherer.gather_input()
	model.update(input, delta)
	input.queue_free()
	RenderingServer.global_shader_parameter_set("player_position", global_position)

func is_grounded() -> bool:
	return grounded or is_on_floor()
	
@rpc("any_peer", "call_remote", "reliable")
func rpc_set_position(pos):
	position = pos
	velocity = Vector3.ZERO
