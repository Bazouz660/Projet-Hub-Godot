extends Button

func _on_pressed():
	MultiplayerManager.host_game()
	GameManager.change_gui_scene("res://scene/interface/hud/hud.tscn")
