extends Marker3D

@export var follow_mouse = true

func _input(_delta):

	if !follow_mouse:
		return

	var space = get_world_3d().direct_space_state
	var camera = get_viewport().get_camera_3d()
	if not camera:
		print("No camera found")
		return
	var mousePos = get_viewport().get_mouse_position()

	var from = camera.project_ray_origin(mousePos)
	var to = from + camera.project_ray_normal(mousePos) * 1000

	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space.intersect_ray(query)

	if result:
		global_position = result.position
