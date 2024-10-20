extends Button

@onready var ip_input = $"../IpInput" as LineEdit
@onready var port_input = $"../PortInput" as LineEdit

func _on_pressed():
	var ip : String = ip_input.text
	var port : int = port_input.text.to_int()
	MultiplayerManager.join_game(ip, port)
	GameManager.change_gui_scene("res://scene/interface/hud/hud.tscn")
	
