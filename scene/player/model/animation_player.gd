@tool
extends AnimationPlayer

@export var set_anims_interpolation_nearest : bool = false

func _process(_delta):
	if Engine.is_editor_hint() and set_anims_interpolation_nearest:
		var anim_library = get_animation_library("")
		for anim_name in get_animation_list():
			var anim = anim_library.get_animation(anim_name)
			for i in anim.get_track_count():
				anim.track_set_interpolation_type(i, Animation.INTERPOLATION_NEAREST)
				var path : String = anim.track_get_path(i)
				path = path.rsplit(":", 1)[1]
				path = "GeneralSkeleton:" + path
				anim.track_set_path(i, path)
