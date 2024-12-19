extends Node

signal scene_loaded(scene_path: String, is_3d: bool)
signal loading_progress(progress: float, is_3d: bool)

var root: Root
var disable_player_input: bool = false
var current_3d_scene: Node3D = null
var current_gui_scene: Control = null
var scenes_in_memory: Dictionary

# Separate loading states for GUI and 3D scenes
var _loading_3d = {
	"is_loading": false,
	"progress": 0.0,
	"scene_path": "",
	"use_threads": true
}

var _loading_gui = {
	"is_loading": false,
	"progress": 0.0,
	"scene_path": "",
	"use_threads": false
}

func change_gui_scene(new_scene_path: String) -> void:
	if _loading_gui.is_loading:
		push_warning("GUI scene loading already in progress")
		return

	_loading_gui.is_loading = true
	_loading_gui.progress = 0.0
	_loading_gui.scene_path = new_scene_path

	# Handle current GUI scene
	if current_gui_scene != null:
		scenes_in_memory.erase(current_gui_scene.scene_file_path)
		current_gui_scene.queue_free()

	if new_scene_path == "":
		_finish_loading_gui(null)
		return

	# Start loading based on threading preference
	if !scenes_in_memory.has(new_scene_path):
		var resource = load(new_scene_path)
		var new_scene = resource.instantiate()
		_finish_loading_gui(new_scene)
	else:
		_finish_loading_gui(scenes_in_memory[new_scene_path])

func change_3d_scene(new_scene_path: String) -> void:
	if _loading_3d.is_loading:
		push_warning("3D scene loading already in progress")
		return

	# Make loading screen visible
	root.loading_scene.reset()
	root.loading_scene.visible = true

	_loading_3d.is_loading = true
	_loading_3d.progress = 0.0
	_loading_3d.scene_path = new_scene_path

	# Handle current 3D scene
	if current_3d_scene != null:
		scenes_in_memory.erase(current_3d_scene.scene_file_path)
		current_3d_scene.queue_free()

	if new_scene_path == "":
		_finish_loading_3d(null)
		return

	# Start loading based on threading preference
	ResourceLoader.load_threaded_request(new_scene_path, "", true)


func _process(_delta: float) -> void:
	_process_loading(_loading_3d, true)

func _process_loading(loading_state: Dictionary, is_3d: bool) -> void:
	if not loading_state.is_loading or not loading_state.use_threads:
		return

	if scenes_in_memory.has(loading_state.scene_path):
		return

	var progress = []
	var status = ResourceLoader.load_threaded_get_status(loading_state.scene_path, progress)

	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			loading_state.progress = progress[0]
			loading_progress.emit(progress[0], is_3d)
			root.loading_scene.update_progress(progress[0])

		ResourceLoader.THREAD_LOAD_LOADED:
			var resource = ResourceLoader.load_threaded_get(loading_state.scene_path)
			var new_scene = resource.instantiate()
			if is_3d:
				_finish_loading_3d(new_scene)
			else:
				_finish_loading_gui(new_scene)

		ResourceLoader.THREAD_LOAD_FAILED:
			push_error("Scene loading failed: " + loading_state.scene_path)
			if is_3d:
				_finish_loading_3d(null)
			else:
				_finish_loading_gui(null)

func _finish_loading_gui(new_scene) -> void:
	if new_scene != null:
		root.gui.add_child(new_scene)
		current_gui_scene = new_scene

	#scene_loaded.emit(_loading_gui.scene_path, false)

	# Reset GUI loading state
	_loading_gui.is_loading = false
	_loading_gui.progress = 0.0
	_loading_gui.scene_path = ""

func _finish_loading_3d(new_scene) -> void:
	root.loading_scene.visible = false # Remove the loading screen

	if new_scene != null:
		root.world.get_node("SubViewportContainer/SubViewport").add_child(new_scene)
		current_3d_scene = new_scene

	scene_loaded.emit(_loading_3d.scene_path, true)

	# Reset 3D loading state
	_loading_3d.is_loading = false
	_loading_3d.progress = 0.0
	_loading_3d.scene_path = ""


func quit_game() -> void:
	get_tree().quit()
	MultiplayerManager.close_connection()
