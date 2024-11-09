extends Node3D

@onready var body = %body
@onready var head = %head

func accept_skeleton(skeleton : Skeleton3D):
	body.skeleton = skeleton.get_path()
	head.skeleton = skeleton.get_path()
