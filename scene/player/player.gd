extends CharacterBody3D
class_name Player

@onready var input_gatherer := $Input as InputGatherer
@onready var model := $Model as HumanoidModel
@onready var presentation := $Presentation as PlayerPresentation
@onready var camera := $Camera/PreventRotationCopy/CameraPivot/Camera3D
@onready var step_cast := $StepCast as ShapeCast3D
@onready var inventory := $InventoryComponent as InventoryComponent
@onready var stamina := $StaminaComponent as StaminaComponent
@onready var collision_shape := $CollisionShape3D as CollisionShape3D
@onready var material_detector := $MaterialDetector as MaterialDetector


var sensitivity = 0.003;
var yaw = 0.0;
var grounded = false;
@export var height = 1.0

## TO DO: MAKE THIS A GLOBAL VARIABLE
const WATER_LEVEL = 0;

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _ready():
	SceneManager.disable_player_input = false
	presentation.accept_skeleton(model.skeleton)
	presentation.register_sounds(model.sound_manager)
	model.animator.play("ready_idle")
	camera.current = is_multiplayer_authority()

func _physics_process(delta):
	if not is_multiplayer_authority():
		return
	var input = input_gatherer.gather_input()
	model.update(input, delta)
	input.queue_free()
	RenderingServer.global_shader_parameter_set("player_position", global_position)

func is_grounded() -> bool:
	return grounded or is_on_floor()
	
func is_in_water() -> bool:
	return global_position.y + height <= WATER_LEVEL
	
@rpc("any_peer", "call_remote", "reliable")
func rpc_set_position(pos):
	position = pos
	velocity = Vector3.ZERO
