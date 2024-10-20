extends Node

var root : Root

var disable_player_input : bool = false

var _current_3d_scene : Node3D = null
var _current_gui_scene : Control = null

func change_gui_scene(new_scene : String, delete: bool = true, keep_running: bool = false) -> void:
	if _current_gui_scene != null:
		if delete:
			_current_gui_scene.queue_free() # Removes node entirely
		elif keep_running:
			_current_gui_scene.visible = false # Keep in memory and running
		else:
			root.gui.remove_child(_current_gui_scene) # Keep in memory, doesn't run
	if new_scene == "":
		_current_gui_scene = null
		return
	var new = load(new_scene).instantiate()
	root.gui.add_child(new)
	_current_gui_scene = new
	
func change_3d_scene(new_scene : String, delete: bool = true, keep_running: bool = false) -> void:
	if _current_3d_scene != null:
		if delete:
			_current_3d_scene.queue_free() # Removes node entirely
		elif keep_running:
			_current_3d_scene.visible = false # Keep in memory and running
		else:
			root.world.get_node("SubViewportContainer/SubViewport").remove_child(_current_3d_scene) # Keep in memory, doesn't run
	if new_scene == "":
		_current_3d_scene = null
		return
	var new = load(new_scene).instantiate()
	root.world.get_node("SubViewportContainer/SubViewport").add_child(new)
	_current_3d_scene = new
	
func quit_game():
	MultiplayerManager.close_connection()
	get_tree().quit()
