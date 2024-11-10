extends Node3D
class_name PlayerPresentation

@onready var body = %body
@onready var head = %head

func accept_skeleton(skeleton : Skeleton3D):
	body.skeleton = skeleton.get_path()
	head.skeleton = skeleton.get_path()
