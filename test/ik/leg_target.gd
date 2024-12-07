extends Marker3D

@export var raycast: RayCast3D

# # set position to the hit position
func _physics_process(delta):
	if raycast.is_colliding():
		global_position = raycast.get_collision_point()
