@tool
extends AnimationPlayer

@export var fps: int = 15
var counter: float = 0

@export var set_anims_interpolation_nearest: bool = false:
	set(value):
		set_anims_interpolation_nearest = value
		if !value:
			return
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

func _process(delta):
	if callback_mode_method == ANIMATION_CALLBACK_MODE_PROCESS_MANUAL:
		counter += delta
		if counter >= 1.0 / fps:
			advance(counter)
			counter = 0

func _ready():
	_configure_blend_times()

func _is_uppercase(p_char: String) -> bool:
	print(p_char, p_char.to_upper())
	return p_char == p_char.to_upper()

func _configure_blend_times():
	_set_default_blend_times(0.2)
	set_blend_time("slash_1", "slash_2", 0)
	set_blend_time("slash_3", "run", 0)

func _set_default_blend_times(blend_time: float):
	for anim_name in get_animation_list():
		for anim_name2 in get_animation_list():
			set_blend_time(anim_name, anim_name2, blend_time)
			set_blend_time(anim_name2, anim_name, blend_time)