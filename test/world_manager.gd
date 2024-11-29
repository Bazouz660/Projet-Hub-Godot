@tool
extends Node3D

		
func _ready():
	TimeManager.start()

func _input(_event):
	if Input.is_key_pressed(KEY_0):
		get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME

	if Input.is_key_pressed(KEY_1):
		get_viewport().debug_draw = Viewport.DEBUG_DRAW_DISABLED
