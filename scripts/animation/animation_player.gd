@tool
extends AnimationPlayer

@export var fps: int = 15
var counter: float = 0
@export var configure_blend_times: bool = true

@export var interpolation_type: Animation.InterpolationType = Animation.INTERPOLATION_NEAREST
@export_tool_button("Set interpolation to nearest")
var toolbutton_set_anims_interpolation_nearest = _set_anims_interpolation_nearest.bind()

@export var anim_to_update: String = "@All"

@export var skeleton_path: String = "GeneralSkeleton"
@export_tool_button("Change skeleton path")
var toolbutton_set_skeleton_path = _set_skeleton_path.bind()

@export var track_prefix_from: String = "mixamorig_"
@export var track_prefix_to: String = "mixamorig"
@export_tool_button("Change track prefix")
var toolbutton_set_track_prefix = _set_track_prefix.bind()

@export_category("Root Motion Tools")
@export var move_database: AnimationPlayer
@export var animation_to_extract_root_motion: String = ""
@export_tool_button("Extract root motion")
var toolbutton_extract_root_motion = _extract_root_motion.bind()

@export_category("Scale Tools")
@export var scale_factor: float = 1.0
@export_tool_button("Scale animations positions")
var toolbutton_scale_animations_positions = _scale_animations_positions.bind()

@export_category("Save Tools")
@export var save_folder: String = ""
@export_tool_button("Save all animations")
var toolbutton_save_all_animations = _save_all_animations.bind()

func _set_skeleton_path():
	if anim_to_update == "@All":
		var anim_library = get_animation_library("")
		for anim_name in get_animation_list():
			_set_skeleton_path_single(anim_library, anim_name)
	else:
		_set_skeleton_path_single(get_animation_library(""), anim_to_update)

func _set_skeleton_path_single(anim_library, anim_name):
	var anim = anim_library.get_animation(anim_name)
	for i in anim.get_track_count():
		var path: String = anim.track_get_path(i)
		path = path.split(":")[1]
		path = skeleton_path + ":" + path
		print("New path: ", path)
		anim.track_set_path(i, path)

func _set_track_prefix():
	if anim_to_update == "@All":
		var anim_library = get_animation_library("")
		for anim_name in get_animation_list():
			_set_track_prefix_single(anim_library, anim_name)
	else:
		_set_track_prefix_single(get_animation_library(""), anim_to_update)


func _set_track_prefix_single(anim_library, anim_name):
	print("Processing animation: ", anim_name)
	var anim = anim_library.get_animation(anim_name)
	for i in anim.get_track_count():
		var path: String = anim.track_get_path(i)
		var _skeleton_path = path.split(":")[0]
		path = path.split(":")[1]
		# check if the first word is "mixamorig"*
		var index = path.find(track_prefix_from)
		if index != 0:
			continue
		if path.find(track_prefix_to) != -1 and path.find(track_prefix_from) == -1:
			continue
		path = path.replace(track_prefix_from, track_prefix_to)
		path = _skeleton_path + ":" + path
		print("New path: ", path)
		anim.track_set_path(i, path)

# func _rename_tracks():
# 	var anim_library = get_animation_library("")
# 	for anim_name in get_animation_list():
# 		var anim = anim_library.get_animation(anim_name)
# 		for i in anim.get_track_count():
# 			var path: String = anim.track_get_path(i)
# 			if path.find("mixamorig") == -1: # not a mixamo track
# 				continue
# 			path = path.replace("_", "")
# 			path = path.rsplit(":", 1)[1]
# 			# remove "mixamorig" from the path
# 			if path.find("mixamorig") != -1:
# 				path = path.replace("mixamorig", "")
# 			# if path starts swith an underscore, remove it
# 			if path[0] == "_":
# 				path = path.substr(1, path.length())
# 			print("New path: ", path)
# 			path = track_prefix + path
# 			anim.track_set_path(i, path)

func _set_anims_interpolation_nearest() -> void:
	var anim_library = get_animation_library("")
	for anim_name in get_animation_list():
		var anim = anim_library.get_animation(anim_name)
		for i in anim.get_track_count():
			anim.track_set_interpolation_type(i, interpolation_type)

func _process(delta):
	if callback_mode_method == ANIMATION_CALLBACK_MODE_PROCESS_MANUAL:
		counter += delta
		if counter >= 1.0 / fps:
			advance(counter)
			counter = 0

func _ready():
	if configure_blend_times:
		print("Configuringblendtimes")
		_configure_blend_times()

func _is_uppercase(p_char: String) -> bool:
	print(p_char, p_char.to_upper())
	return p_char == p_char.to_upper()

func _configure_blend_times():
	_set_default_blend_times(0.2)
	set_blend_time("slash_1", "slash_2", 0)

func _set_default_blend_times(blend_time: float):
	for anim_name in get_animation_list():
		for anim_name2 in get_animation_list():
			set_blend_time(anim_name, anim_name2, blend_time)
			set_blend_time(anim_name2, anim_name, blend_time)

# DEVELOPMENT LAYER FUNCTIONAL, IT DOES MODIFY ASSETS, UNCOMMENT IF YOU KNOW WHAT YOU ARE DOING
func _extract_root_motion():
	var animation = get_animation(animation_to_extract_root_motion) as Animation
	var hips_track = animation.find_track("GeneralSkeleton: mixamorigHips", Animation.TYPE_POSITION_3D)
	var backend_animation = move_database.get_animation(animation_to_extract_root_motion + "_params")
	var backend_track_path = "MoveDatabase: root_position"
	var backend_track = backend_animation.find_track(backend_track_path, Animation.TYPE_VALUE)
	if backend_track == -1:
		print("Error: track not found: " + backend_track_path)
		return

	print(animation.track_get_key_count(hips_track))
	for i: int in animation.track_get_key_count(hips_track):
		var position = animation.track_get_key_value(hips_track, i)
		var time = animation.track_get_key_time(hips_track, i)
		print(str(position) + "at" + str(time))
		var position_without_z = position
		backend_animation.track_insert_key(backend_track, time, position)
		position_without_z.z = 0
		animation.track_set_key_value(hips_track, i, position_without_z)
		ResourceSaver.save(animation, "res: / / test / " + animation_to_extract_root_motion + "_rooted.res")

# scales all the animations positions by a factor
func _scale_animations_positions():
	if anim_to_update == "@All":
		var anim_library = get_animation_library("")
		for anim_name in get_animation_list():
			_scale_animation_position(anim_library, anim_name)
	else:
		_scale_animation_position(get_animation_library(""), anim_to_update)

func _scale_animation_position(anim_library, anim_name):
	var anim = anim_library.get_animation(anim_name)
	for i in anim.get_track_count():
		var path: String = anim.track_get_path(i)
		if path.find("mixamorig") == -1: # not a mixamo track
			continue
		if anim.track_get_type(i) != Animation.TYPE_POSITION_3D:
			continue
		for j in anim.track_get_key_count(i):
			var position = anim.track_get_key_value(i, j)
			position *= scale_factor
			anim.track_set_key_value(i, j, position)

func _save_all_animations():
	var anim_library = get_animation_library("")
	for anim_name in get_animation_list():
		var anim = anim_library.get_animation(anim_name)
		if save_folder.ends_with(" / ") == false:
			save_folder += " / "
		var path = "res: / / " + save_folder + anim_name + ".res"
		anim.take_over_path(path)
		ResourceSaver.save(anim, path)
