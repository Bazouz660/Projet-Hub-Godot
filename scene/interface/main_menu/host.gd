extends Button

func _on_pressed():
	Global.game_manager.host_game()
	Global.game_manager.change_gui_scene("res://scene/interface/hud/hud.tscn")
