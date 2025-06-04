@tool
extends Node
class_name LayeredAnimationSystem

@export_tool_button("Setup Animation Tree")
var setup_animation_tree_button = Callable(self, "_setup_animation_tree")

@export var animation_tree: AnimationTree
@export var skeleton_name: String = "%Skeleton"

var blend_tree: AnimationNodeBlendTree
var last_layer_name: String = ""
var layer_count: int = 0
var animation_layers: Array[AnimationLayer] = []
var blend_nodes: Dictionary[String, AnimationNodeBlend2] = {}

var _layers_hash_map: Dictionary[String, AnimationLayer] = {}
var _blend_nodes_layers_hash_map: Dictionary[String, String] = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not animation_tree:
		push_error("LayeredAnimationSystem: AnimationTree not assigned!")
		return

	# Initialize the animation tree structure
	_setup_animation_tree()

func _setup_animation_tree() -> void:
	print("Setting up Animation Tree...")
	layer_count = 0
	last_layer_name = ""
	blend_nodes.clear()
	blend_tree = AnimationNodeBlendTree.new()

	animation_layers = _get_children()

	for layer in animation_layers:
		_add_animation_layer(layer)

	# Connect the output to the last layer
	blend_tree.connect_node("output", 0, last_layer_name)

	animation_tree.tree_root = blend_tree

	# set the parameters for the animation tree
	var layer_index := 1
	for blend_node_name in blend_nodes:
		var weight := animation_layers[layer_index].weight
		animation_tree.set("parameters/" + blend_node_name + "/blend_amount", weight)

func _get_children() -> Array[AnimationLayer]:
	_layers_hash_map.clear()
	_blend_nodes_layers_hash_map.clear()
	var children: Array[AnimationLayer] = []
	for child in get_children():
		if child is AnimationLayer:
			children.append(child)
			_layers_hash_map[child.name] = child
	return children

func _add_animation_layer(layer: AnimationLayer) -> void:
	var animation_node := AnimationNodeAnimation.new()
	animation_node.animation = layer.animation
	blend_tree.add_node(layer.name, animation_node)

	var time_seek_node := AnimationNodeTimeSeek.new()
	var time_seek_name := layer.name + "_time_seek"
	# Enable explicit elapse to prevent automatic timeline advancement
	time_seek_node.explicit_elapse = true
	blend_tree.add_node(time_seek_name, time_seek_node)
	blend_tree.connect_node(time_seek_name, 0, layer.name)

	layer_count += 1
	if layer_count >= 2:
		var blend_node := AnimationNodeBlend2.new()
		var blend_node_name := "blend_" + str(layer.name + "_" + last_layer_name)

		if layer.mask.is_empty():
			blend_node.filter_enabled = false
		else:
			blend_node.filter_enabled = true

		for mask_bone in layer.mask:
			var bone_name := AnimationLayer.get_bone_name(mask_bone)
			var bone_path := skeleton_name + ":" + bone_name
			blend_node.set_filter_path(bone_path, true)

		blend_tree.add_node(blend_node_name, blend_node)
		blend_tree.connect_node(blend_node_name, 0, last_layer_name)
		blend_tree.connect_node(blend_node_name, 1, time_seek_name)
		last_layer_name = blend_node_name
		blend_nodes[blend_node_name] = blend_node
		_blend_nodes_layers_hash_map[layer.name] = blend_node_name
	else:
		last_layer_name = time_seek_name

func set_layer_weight(layer_name: String, weight: float) -> void:
	var layer: AnimationLayer = _layers_hash_map.get(layer_name, null)
	if not layer:
		return
	layer.weight = weight
	var blend_node_name: String = _blend_nodes_layers_hash_map.get(layer_name, null)
	if not blend_node_name:
		return
	var blend_node: AnimationNodeBlend2 = blend_nodes.get(blend_node_name, null)
	if not blend_node:
		return
	animation_tree.set("parameters/" + blend_node_name + "/blend_amount", weight)

func get_layer_weight(layer_name: String) -> float:
	var layer: AnimationLayer = _layers_hash_map.get(layer_name, null)
	if not layer:
		return -1.0
	return layer.weight

func set_layer_animation(layer_name: String, animation: String) -> void:
	var layer: AnimationLayer = _layers_hash_map.get(layer_name, null)
	if not layer:
		return
	layer.animation = animation
	var animation_node: AnimationNodeAnimation = blend_tree.get_node(layer.name) as AnimationNodeAnimation
	if not animation_node:
		return
	animation_node.animation = animation

func set_layer_mask(layer_name: String, mask: Array[String]) -> void:
	var layer: AnimationLayer = _layers_hash_map.get(layer_name, null)
	if not layer:
		return
	var blend_node_name: String = _blend_nodes_layers_hash_map.get(layer_name, null)
	if not blend_node_name:
		return
	var blend_node: AnimationNodeBlend2 = blend_nodes.get(blend_node_name, null)
	if not blend_node:
		return

	if mask.is_empty():
		blend_node.filter_enabled = false
	else:
		blend_node.filter_enabled = true

	for bone_name in mask:
		var bone_path := skeleton_name + ":" + bone_name
		blend_node.set_filter_path(bone_path, true)


# Animation play options for flexibility
enum PlayOptions {
	NONE = 0,
	RESET_TIMELINE = 1,
	RESET_ROOT_MOTION = 2,
	PRESERVE_VELOCITY = 4,
	SKIP_IF_SAME = 8
}

func layer_play(layer_name: String, animation: String, backwards: bool = false, options: int = PlayOptions.RESET_TIMELINE) -> void:
	var layer: AnimationLayer = _layers_hash_map.get(layer_name, null)
	if not layer:
		return
	
	# Check if we should skip playing the same animation
	if options & PlayOptions.SKIP_IF_SAME and layer.animation == animation:
		return
	
	# Store current velocity if needed
	var character_body = _find_character_body()
	var current_velocity = Vector3.ZERO
	if (options & PlayOptions.PRESERVE_VELOCITY) and character_body and character_body.has_method("get_velocity"):
		current_velocity = character_body.get_velocity()
	
	# Clear root motion accumulator if requested
	if options & PlayOptions.RESET_ROOT_MOTION:
		clear_root_motion_accumulator()
	
	# Reset timeline if requested
	if options & PlayOptions.RESET_TIMELINE:
		if backwards:
			_reset_layer_timeline_to_end_sync(layer_name, animation)
		else:
			_reset_layer_timeline_sync(layer_name)
	
	# Set the new animation
	layer.animation = animation
	var animation_node: AnimationNodeAnimation = blend_tree.get_node(layer.name) as AnimationNodeAnimation
	if not animation_node:
		return
	animation_node.animation = animation
	animation_node.play_mode = AnimationNodeAnimation.PLAY_MODE_BACKWARD if backwards else AnimationNodeAnimation.PLAY_MODE_FORWARD
	
	# Handle root motion reset if requested
	if options & PlayOptions.RESET_ROOT_MOTION and character_body and character_body.has_method("set_velocity"):
		await get_tree().process_frame
		var reset_velocity = Vector3(0, current_velocity.y if (options & PlayOptions.PRESERVE_VELOCITY) else 0, 0)
		character_body.set_velocity(reset_velocity)

func layer_play_backwards(layer_name: String, animation: String, options: int = PlayOptions.RESET_TIMELINE) -> void:
	layer_play(layer_name, animation, true, options)

func reset_layer_timeline(layer_name: String) -> void:
	_reset_layer_timeline_immediate(layer_name)

func _reset_layer_timeline_immediate(layer_name: String) -> void:
	"""Immediately reset timeline to start position to prevent root motion jumps"""
	var layer: AnimationLayer = _layers_hash_map.get(layer_name, null)
	if not layer:
		return
	var seek_node_name := layer.name + "_time_seek"

	# Set seek_request to 0.0 to reset timeline
	animation_tree.set("parameters/" + seek_node_name + "/seek_request", 0.0)

	# Process one frame to ensure the seek takes effect
	await get_tree().process_frame

func _reset_layer_timeline_sync(layer_name: String) -> void:
	"""Synchronously reset timeline to start position"""
	var layer: AnimationLayer = _layers_hash_map.get(layer_name, null)
	if not layer:
		return
	var seek_node_name := layer.name + "_time_seek"
	animation_tree.set("parameters/" + seek_node_name + "/seek_request", 0.0)

func _reset_layer_timeline_to_end(layer_name: String, animation_name: String) -> void:
	"""Reset timeline to end position for backwards playback"""
	var layer: AnimationLayer = _layers_hash_map.get(layer_name, null)
	if not layer:
		return

	# Get animation length
	var anim_length := _get_animation_length(animation_name)
	if anim_length <= 0.0:
		return

	var seek_node_name := layer.name + "_time_seek"
	animation_tree.set("parameters/" + seek_node_name + "/seek_request", anim_length)

	# Process one frame to ensure the seek takes effect
	await get_tree().process_frame

func _reset_layer_timeline_to_end_sync(layer_name: String, animation_name: String) -> void:
	"""Synchronously reset timeline to end position for backwards playback"""
	var layer: AnimationLayer = _layers_hash_map.get(layer_name, null)
	if not layer:
		return

	# Get animation length
	var anim_length := _get_animation_length(animation_name)
	if anim_length <= 0.0:
		anim_length = 1.0 # Fallback to 1 second if can't determine length

	var seek_node_name := layer.name + "_time_seek"
	animation_tree.set("parameters/" + seek_node_name + "/seek_request", anim_length)

func _get_animation_length(animation_name: String) -> float:
	"""Get the length of an animation"""
	if not animation_tree or not animation_tree.tree_root:
		return 0.0

	# Try to get from animation player first
	var anim_player = animation_tree.get_animation_player()
	if anim_player and anim_player.has_animation(animation_name):
		return anim_player.get_animation(animation_name).length

	# Try to get from animation libraries
	var libraries = animation_tree.get_animation_libraries()
	for lib_name in libraries:
		var lib = libraries[lib_name]
		if lib.has_animation(animation_name):
			return lib.get_animation(animation_name).length

	return 0.0

# Root motion safe animation switching
func layer_play_with_root_motion_reset(layer_name: String, animation: String) -> void:
	"""Play animation with proper root motion handling to prevent impulses"""
	var options = PlayOptions.RESET_TIMELINE | PlayOptions.RESET_ROOT_MOTION | PlayOptions.PRESERVE_VELOCITY | PlayOptions.SKIP_IF_SAME
	layer_play(layer_name, animation, false, options)

func layer_play_backwards_with_root_motion_reset(layer_name: String, animation: String) -> void:
	"""Play animation backwards with proper root motion handling"""
	var options = PlayOptions.RESET_TIMELINE | PlayOptions.RESET_ROOT_MOTION | PlayOptions.PRESERVE_VELOCITY | PlayOptions.SKIP_IF_SAME
	layer_play(layer_name, animation, true, options)

func layer_play_safe(layer_name: String, animation: String, backwards: bool = false) -> void:
	"""Play animation with safe defaults - skip if same, reset timeline, preserve velocity"""
	var options = PlayOptions.RESET_TIMELINE | PlayOptions.PRESERVE_VELOCITY | PlayOptions.SKIP_IF_SAME
	layer_play(layer_name, animation, backwards, options)

func layer_play_force(layer_name: String, animation: String, backwards: bool = false) -> void:
	"""Force play animation even if same, with full root motion reset"""
	var options = PlayOptions.RESET_TIMELINE | PlayOptions.RESET_ROOT_MOTION | PlayOptions.PRESERVE_VELOCITY
	layer_play(layer_name, animation, backwards, options)

func _find_character_body() -> Node:
	"""Find CharacterBody3D in parent hierarchy for root motion handling"""
	var current = get_parent()
	while current:
		if current is CharacterBody3D:
			return current
		current = current.get_parent()
	return null

# Improved set_layer_weight with root motion considerations
func set_layer_weight_smooth(layer_name: String, weight: float, reset_timeline: bool = false) -> void:
	"""Set layer weight with optional timeline reset to prevent root motion jumps"""
	var layer: AnimationLayer = _layers_hash_map.get(layer_name, null)
	if not layer:
		return

	if reset_timeline:
		_reset_layer_timeline_sync(layer_name)

	layer.weight = weight
	var blend_node_name: String = _blend_nodes_layers_hash_map.get(layer_name, null)
	if not blend_node_name:
		return
	var blend_node: AnimationNodeBlend2 = blend_nodes.get(blend_node_name, null)
	if not blend_node:
		return
	animation_tree.set("parameters/" + blend_node_name + "/blend_amount", weight)

# Advanced root motion transition methods
func transition_to_animation(layer_name: String, new_animation: String, transition_time: float = 0.3) -> void:
	"""Smoothly transition to a new animation with root motion preservation"""
	var layer: AnimationLayer = _layers_hash_map.get(layer_name, null)
	if not layer:
		return

	var character_body = _find_character_body()
	var initial_velocity = Vector3.ZERO
	if character_body and character_body.has_method("get_velocity"):
		initial_velocity = character_body.get_velocity()

	# Create a smooth transition using weight animation
	var tween = create_tween()
	var current_weight = get_layer_weight(layer_name)

	# Fade out current animation
	tween.tween_method(
		func(weight: float): set_layer_weight(layer_name, weight),
		current_weight,
		0.0,
		transition_time * 0.5
	)

	# Switch animation at mid-point
	tween.tween_callback(func(): _switch_animation_safe(layer_name, new_animation))

	# Fade in new animation
	tween.tween_method(
		func(weight: float): set_layer_weight(layer_name, weight),
		0.0,
		current_weight,
		transition_time * 0.5
	)

	# Restore velocity at the end to prevent drift
	if character_body and character_body.has_method("set_velocity"):
		tween.tween_callback(func(): character_body.set_velocity(initial_velocity))

func _switch_animation_safe(layer_name: String, animation: String) -> void:
	"""Internal method to switch animation safely during transition"""
	var layer: AnimationLayer = _layers_hash_map.get(layer_name, null)
	if not layer:
		return

	_reset_layer_timeline_sync(layer_name)
	layer.animation = animation
	var animation_node: AnimationNodeAnimation = blend_tree.get_node(layer.name) as AnimationNodeAnimation
	if animation_node:
		animation_node.animation = animation
		animation_node.play_mode = AnimationNodeAnimation.PLAY_MODE_FORWARD

# Debug and utility methods for root motion
func get_current_root_motion() -> Vector3:
	"""Get current root motion translation from animation tree"""
	if animation_tree:
		return animation_tree.get_root_motion_position()
	return Vector3.ZERO

func get_current_root_motion_rotation() -> Quaternion:
	"""Get current root motion rotation from animation tree"""
	if animation_tree:
		return animation_tree.get_root_motion_rotation()
	return Quaternion.IDENTITY

func debug_print_layer_status() -> void:
	"""Debug function to print current layer states"""
	print("=== Layered Animation System Status ===")
	for layer_name in _layers_hash_map.keys():
		var layer = _layers_hash_map[layer_name]
		var weight = get_layer_weight(layer_name)
		var seek_node_name = layer_name + "_time_seek"
		var time_param = "parameters/" + seek_node_name + "/time"
		var current_time = animation_tree.get(time_param) if animation_tree.has_method("get") else 0.0
		print("Layer '%s': Animation='%s', Weight=%.2f, Time=%.2f" % [layer_name, layer.animation, weight, current_time])
	print("Root Motion: Pos=%s, Rot=%s" % [get_current_root_motion(), get_current_root_motion_rotation()])
	print("========================================")

# Additional method to force clear root motion accumulator
func clear_root_motion_accumulator() -> void:
	"""Force clear the root motion accumulator to prevent impulses"""
	if animation_tree:
		# Advance by 0 to clear accumulator
		animation_tree.advance(0.0)
		# Alternative method: directly clear the accumulator if available
		if animation_tree.has_method("reset_root_motion_accumulator"):
			animation_tree.reset_root_motion_accumulator()