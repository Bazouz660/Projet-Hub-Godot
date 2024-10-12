extends Button

@onready var ip_input = $"../IpInput"
@onready var port_input = $"../PortInput"
@onready var connect_bt = $"../Connect"

func _on_pressed():
	connect_bt.visible = !connect_bt.visible
	ip_input.visible = !ip_input.visible
	port_input.visible = !port_input.visible
