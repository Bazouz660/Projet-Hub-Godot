extends Control

@onready var messages = %Messages as TextEdit
@onready var message = %Message as LineEdit
@onready var timer = $Timer

var username : String = "Test"
var tween : Tween
var mouse_mode
var _first_message : bool = true

const MAX_LINES = 5

var count : float = 0.0

func _ready():
	MultiplayerManager.active_player_loaded.connect(func(id): username = str(id))
	timer.wait_time = 3.0
	timer.timeout.connect(_on_timer_timeout)
	messages.text_set.connect(_on_messages_changed)
	
func _on_messages_changed():	
	if messages.get_line_count() > MAX_LINES:
		messages.remove_line_at(0)
	messages.scroll_vertical = messages.get_line_count()

func _on_timer_timeout():
	tween = create_tween()
	tween.finished.connect(func(): self.hide())
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)

@rpc("any_peer", "call_local", "reliable")
func _msg_rpc(usrnm : String, msg : String):
	var str : String = usrnm + ": " + msg

	if _first_message:
		_first_message = false
	else:
		str = "\n" + str

	messages.text += str
	
	timer.stop()
	self.show()
	self.modulate = Color.WHITE
	if is_instance_valid(tween) and tween.is_running():
		tween.kill()
		
	if !message.has_focus():
		timer.start()

func _on_message_text_submitted(new_text):
	message.release_focus()
	if new_text == "":
		return

	_msg_rpc.rpc(username, new_text)
	message.text = ""

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_text_completion_accept"):
		if message.has_focus():
			message.release_focus()
		else:
			self.show()
			self.modulate = Color.WHITE
			if is_instance_valid(tween) and tween.is_running():
				tween.kill()
			message.grab_focus()


func _on_message_focus_exited():
	timer.stop()
	timer.start()
	Input.mouse_mode = mouse_mode
	SceneManager.disable_player_input = false

func _on_message_focus_entered():
	timer.stop()
	mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	SceneManager.disable_player_input = true
