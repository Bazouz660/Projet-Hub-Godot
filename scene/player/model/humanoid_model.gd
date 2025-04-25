extends Node3D
class_name HumanoidModel

@export var active_weapon: Weapon = null

@onready var DEFAULT_GRAVITY: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var humanoid := $".." as CharacterBody3D
@onready var sound_manager := $SoundManager as HumanoidSoundManager
@onready var skeleton := %GeneralSkeleton as Skeleton3D
@onready var animator := $Animator as SplitAnimator
@onready var combat := $Combat as HumanoidCombat
@onready var moves_node = $States
@onready var moves_data_repository := $MovesDataRepository as MovesDataRepository
@onready var resources := $Resources as HumanoidResources
@onready var moves_container := $States as HumanoidStates
@onready var legs := $Legs as Legs

@onready var left_weapon_socket := %LeftWeaponSocket
@onready var right_weapon_socket := %RightWeaponSocket

signal weapon_equipped(scene: PackedScene)
signal weapon_cleared()

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
	legs.current_legs_move = moves_container.get_move_by_name("idle")
	legs.accept_behaviours()

	init_first_move("idle")


##### Consider moving this to a separate file #############################

	# connect inventory signals
	resources.weapon_slot.item_equipped.connect(_on_weapon_equipped)
	resources.weapon_slot.cleared.connect(_on_weapon_cleared)


@rpc("any_peer", "call_remote", "reliable")
func _equip_weapon(prototype_id: String):
	var item = resources.inventory.create_and_add_item(prototype_id)
	if item == null:
		push_error("Item not found: ", prototype_id)
		return

	print("item name: ", item.get_title())
	for property_name in item.get_properties():
		print("property: ", property_name, " value: ", item.get_property(property_name))

	resources.weapon_slot.equip(item)
	print("called equip weapon on peer ", get_tree().get_multiplayer().get_unique_id())


@rpc("any_peer", "call_remote", "reliable")
func _unequip_weapon():
	resources.weapon_slot.clear()
	print("called unequip weapon on peer ", get_tree().get_multiplayer().get_unique_id())


func _on_weapon_cleared():
	print("cleared weapon on peer ", get_tree().get_multiplayer().get_unique_id())

	# If the node has authority, we need to notify other clients
	# that the item has been unequipped
	if is_multiplayer_authority():
		_unequip_weapon.rpc()

	if active_weapon:
		active_weapon.queue_free()
		active_weapon = null

	if right_weapon_socket.get_children().size() > 0:
		for child in right_weapon_socket.get_children():
			child.queue_free()

	weapon_cleared.emit()


func _on_weapon_equipped():
	print("equipped weapon on peer ", get_tree().get_multiplayer().get_unique_id())
	for child in right_weapon_socket.get_children():
		child.queue_free()

	var item := resources.weapon_slot.get_item()

	# If the node has authority, we need to notify other clients
	# that the item has been equipped
	if is_multiplayer_authority():
		_equip_weapon.rpc(item.get_prototype()._id)

	var weapon_collision_scene_path = item.get_property("model")["collision_path"]
	print("weapon collisions: ", weapon_collision_scene_path)
	var weapon_collision_scene = load(weapon_collision_scene_path)
	if !weapon_collision_scene:
		push_error("Weapon collision scene not found: ", weapon_collision_scene_path)
		return

	active_weapon = weapon_collision_scene.instantiate()
	active_weapon.damage = item.get_property("damage")
	active_weapon.holder = self
	right_weapon_socket.add_child(active_weapon)
	active_weapon.scale = Vector3(30, 30, 30) # Fix de con pour la scale de l'arme psk le skeleton a une scale de 0.15

	var weapon_visuals_scene_path = item.get_property("model")["visuals_path"]
	print("weapon visuals: ", weapon_visuals_scene_path)
	var weapon_visuals_scene = load(weapon_visuals_scene_path)
	if !weapon_visuals_scene:
		push_error("Weapon visuals scene not found: ", weapon_visuals_scene_path)
		return
	weapon_equipped.emit(weapon_visuals_scene)

###########################################################################


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


func switch_to(state: String):
	#print('player [', humanoid.name, ']', _current_state, " -> ", state)
	_current_state = state
	current_move.on_exit_state()
	current_move = moves[state]
	current_move.on_enter_state()
	current_move.mark_enter_state()
	resources.pay_resource_cost(current_move)

	print('<<<<< player [', humanoid.name, '] playing: ', current_move.move_name, ' >>>>>')
	animator.play(current_move)


func init_first_move(state: String):
	_current_state = state
	current_move = moves[state]
	current_move.on_enter_state()
	current_move.mark_enter_state()
	animator.play(current_move)

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
