extends Control

@onready var menu_manager = $".."

func _on_vsync_mode_item_selected(index):
	DisplayServer.window_set_vsync_mode(index as DisplayServer.VSyncMode)

func _on_framerate_limit_value_changed(value):
	Engine.max_fps = value

func _on_window_mode_item_selected(index):
	match index:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

func _on_back_button_pressed():
	menu_manager.go_to_last_menu()
