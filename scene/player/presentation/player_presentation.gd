extends Node3D
class_name PlayerPresentation

@onready var model: HumanoidModel

@onready var body = %Body
# @onready var head = %head
@onready var sound_player = $SoundPlayer3D
var weapon_visuals: Node3D


func accept_model(p_model: HumanoidModel):
	model = p_model
	body.skeleton = model.skeleton.get_path()
	# head.skeleton = model.skeleton.get_path()

	model.weapon_equipped.connect(on_weapon_equipped)
	model.weapon_cleared.connect(on_weapon_cleared)

func register_sounds(sound_manager: HumanoidSoundManager):
	sound_manager.sound_player = sound_player

func _process(_delta):
	adjust_weapon_visuals()

func adjust_weapon_visuals():
	if model.active_weapon == null or weapon_visuals == null:
		return
	weapon_visuals.global_position = model.active_weapon.global_position
	weapon_visuals.global_rotation = model.active_weapon.global_rotation

func on_weapon_equipped(scene: PackedScene):
	print("on_weapon_equipped")
	if weapon_visuals != null:
		weapon_visuals.queue_free()

	weapon_visuals = scene.instantiate()
	body.add_child(weapon_visuals)

func on_weapon_cleared():
	if weapon_visuals != null:
		weapon_visuals.queue_free()
		weapon_visuals = null
