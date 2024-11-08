extends Control

@onready var messages = $MarginContainer/VBoxContainer/Messages as TextEdit
@onready var message = $MarginContainer/VBoxContainer/HBoxContainer/Message as LineEdit
@onready var menu_manager = %MenuManager as MenuManager

var username : String = "Test"

func _ready():
	MultiplayerManager.active_player_loaded.connect(func(id): username = str(id))
	set_meta("first_focus", message)

@rpc("any_peer", "call_local", "reliable")
func _msg_rpc(usrnm : String, msg : String):
	messages.text += usrnm + ": " + msg + "\n"

func _on_message_text_submitted(new_text):
	if new_text == "":
		return

	_msg_rpc.rpc(username, new_text)
	message.text = ""
	
	messages.scroll_vertical = messages.get_line_count()


func _on_message_focus_exited():
	menu_manager.close_menu()
