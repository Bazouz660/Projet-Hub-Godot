# Player.gd (attach to your player)
extends CharacterBody3D # or whatever your player extends

@export var xray_material: ShaderMaterial

func _process(delta):
	# Update the player's screen position for the shader
	var camera = get_viewport().get_camera_3d()
	if camera:
		var screen_pos = camera.unproject_position(global_position)
		screen_pos.x /= get_viewport().size.x
		screen_pos.y /= get_viewport().size.y
		xray_material.set_shader_parameter("player_screen_pos", Vector2(screen_pos.x, screen_pos.y))
		xray_material.set_shader_parameter("radius", 1.0) # Adjust based on your needs
