extends CharacterBody3D
class_name Player

@onready var input_gatherer = $Input as InputGatherer
@onready var model = $Model as PlayerModel
@onready var presentation = $Presentation
@onready var camera = $Camera/PreventRotationCopy/CameraPivot/Camera3D
@onready var step_cast = $StepCast as ShapeCast3D
@onready var inventory = $InventoryComponent as InventoryComponent
@onready var stamina = $StaminaComponent as StaminaComponent

var sensitivity = 0.003;
var yaw = 0.0;
var grounded = false;

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _ready():
	SceneManager.disable_player_input = false
	presentation.accept_skeleton(model.skeleton)
	model.animator.play("ready_idle")
	camera.current = is_multiplayer_authority()

	var sword = Item.new("sword")
	var potion = Item.new("potion", "", "", false, 10)
	inventory.add_item(sword)
	inventory.add_item(potion, 5)
	print(inventory.slots[0].item.id, inventory.slots[0].quantity)
	print(inventory.slots[1].item.id, inventory.slots[1].quantity)
	print(inventory.slots[2].item.id, inventory.slots[2].quantity)
	print(inventory.slots[3].item.id, inventory.slots[2].quantity)
	print(inventory.slots[4].item.id, inventory.slots[2].quantity)
	print(inventory.slots[5].item.id, inventory.slots[2].quantity)

func _physics_process(delta):
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
