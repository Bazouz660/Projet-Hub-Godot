extends Node3D
class_name PlayerPresentation

@onready var model : HumanoidModel

@onready var body = %body
@onready var head = %head
@onready var sound_player = $SoundPlayer3D
@onready var sword_visuals = $Sword


func accept_model(p_model : HumanoidModel):
	model = p_model
	body.skeleton = model.skeleton.get_path()
	head.skeleton = model.skeleton.get_path()

func register_sounds(sound_manager : HumanoidSoundManager):
	sound_manager.sound_player = sound_player

func _process(_delta):
	adjust_weapon_visuals()

func adjust_weapon_visuals():
	sword_visuals.global_position = model.active_weapon.global_position
	sword_visuals.global_rotation = model.active_weapon.global_rotation
