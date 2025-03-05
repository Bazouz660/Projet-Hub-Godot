extends Node3D

@onready var xray_mesh: MeshInstance3D = $XraySphereArea/XRaySphere
@onready var xray_area: Area3D = $XraySphereArea
@export var exclusion_list: Array[CollisionObject3D] = []

var ray: RayCast3D
var timer := 0.0

func _ready():
	ray = RayCast3D.new()
	add_child(ray)
	ray.top_level = true


func _process(delta):
	timer += delta
	if timer > 0.1:
		timer = 0.0
	else:
		return

		# Get the camera

	var camera := get_viewport().get_camera_3d()
	# Get the camera's position
	var camera_position = camera.global_position


	# Compute the target position of the ray (relative to the ray position)
	var target_position = xray_mesh.global_transform.origin - camera_position

	ray.global_transform.origin = camera_position
	ray.target_position = target_position
	ray.collide_with_areas = true
	ray.collide_with_bodies = true
	ray.hit_from_inside = true
	ray.exclude_parent = false
	for obj in exclusion_list:
		ray.add_exception(obj)

	ray.enabled = false
	ray.force_raycast_update()

	if ray.is_colliding():
		var collider := ray.get_collider()
		if collider == xray_area:
			_hide()
		else:
			_show()


func _show():
	# Tween the mesh scale to 1.0
	var tween = create_tween()
	tween.tween_property(xray_mesh, "scale", Vector3(1.0, 1.0, 1.0), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _hide():
	# Tween the mesh scale to 0.0
	var tween = create_tween()
	tween.tween_property(xray_mesh, "scale", Vector3.ZERO, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
