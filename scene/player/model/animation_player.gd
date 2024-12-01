@tool
extends AnimationPlayer

@export var set_anims_interpolation_nearest: bool = false

func _ready():
	_configure_blend_times()

func _process(_delta):
	if Engine.is_editor_hint() and set_anims_interpolation_nearest:
		var anim_library = get_animation_library("")
		for anim_name in get_animation_list():
			var anim = anim_library.get_animation(anim_name)
			for i in anim.get_track_count():
				anim.track_set_interpolation_type(i, Animation.INTERPOLATION_NEAREST)
				var path: String = anim.track_get_path(i)
				path = path.replace("_", "")
				path = path.rsplit(":", 1)[1]
				path = "GeneralSkeleton:" + path
				anim.track_set_path(i, path)

func _configure_blend_times():
	_set_default_blend_times(0.2)
	set_blend_time("slash_1", "slash_2", 0)

func _set_default_blend_times(blend_time: float):
	for anim_name in get_animation_list():
		for anim_name2 in get_animation_list():
			set_blend_time(anim_name, anim_name2, blend_time)
			set_blend_time(anim_name2, anim_name, blend_time)