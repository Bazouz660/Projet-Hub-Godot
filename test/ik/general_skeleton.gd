extends Skeleton3D

func _ready():
	print_skeleton_tree()

func print_skeleton_tree():
	print("Skeleton structure:")
	_print_bone_recursive(-1, 0)

func _print_bone_recursive(bone_idx: int, indent: int):
	var indent_str = "  ".repeat(indent)

	if bone_idx == -1:
		# Print all root bones (bones with no parent)
		for i in get_bone_count():
			if get_bone_parent(i) == -1:
				_print_bone_recursive(i, indent)
		return

	# Print current bone
	print(indent_str + "- " + str(get_bone_name(bone_idx)))

	# Print all children bones
	for i in get_bone_count():
		if get_bone_parent(i) == bone_idx:
			_print_bone_recursive(i, indent + 1)
