extends Control

@onready var menu_manager = %MenuManager as MenuManager

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE;
	SceneManager.disable_player_input = true


func _on_resume_pressed():
	if menu_manager.get_history().is_empty():
		menu_manager.close_menu()
	else:
		menu_manager.go_to_last_menu()


func _on_settings_pressed():
	menu_manager.go_to_menu("Settings")


func _on_main_menu_pressed():
	call_deferred("back_to_main_menu")

func back_to_main_menu():
	SceneManager.change_3d_scene("")
	SceneManager.change_gui_scene("res://scene/interface/main_menu/main_menu.tscn")
	MultiplayerManager.close_connection()
	SceneManager.disable_player_input = false

func _on_quit_pressed():
	SceneManager.quit_game()
