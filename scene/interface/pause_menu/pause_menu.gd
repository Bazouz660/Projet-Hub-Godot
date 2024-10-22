extends Control

func _ready():
	pass
	#hide()  # Ensure the pause menu is hidden at the start

func toggle_visibility():
	if is_visible_in_tree():
		hide()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED;
		GameManager.disable_player_input = false
	else:
		show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE;
		GameManager.disable_player_input = true

func _input(_event):
	if Input.is_action_just_pressed("pause"):
		toggle_visibility()


func _on_resume_pressed():
	toggle_visibility()


func _on_settings_pressed():
	pass # Replace with function body.


func _on_main_menu_pressed():
	call_deferred("back_to_main_menu")

func back_to_main_menu():
	GameManager.change_3d_scene("")
	GameManager.change_gui_scene("res://scene/interface/main_menu/main_menu.tscn")
	MultiplayerManager.close_connection()
	hide()
	GameManager.disable_player_input = false

func _on_quit_pressed():
	GameManager.quit_game()
