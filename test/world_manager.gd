@tool
extends Node3D

#@onready var world_generator = $"../WorldGenerator"
#@export var player : CharacterBody3D

#var update_timer := 0.0
#const UPDATE_INTERVAL := 0.5  # Seconds between chunk updates
#
#func _process(delta):
	#update_timer += delta
	#if update_timer >= UPDATE_INTERVAL:
		#world_generator.update_chunks(player.global_position)
		#update_timer = 0.0

func _input(event):
	if Input.is_key_pressed(KEY_CTRL):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
	if Input.is_key_pressed(KEY_0):
		get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME

	if Input.is_key_pressed(KEY_1):
		get_viewport().debug_draw = Viewport.DEBUG_DRAW_DISABLED
