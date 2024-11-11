extends Node3D
class_name PlayerPresentation

@onready var body = %body
@onready var head = %head
@onready var sound_player = $SoundPlayer3D

func accept_skeleton(skeleton : Skeleton3D):
	body.skeleton = skeleton.get_path()
	head.skeleton = skeleton.get_path()

func register_sounds(sound_manager : HumanoidSoundManager):
	sound_manager.sound_player = sound_player
