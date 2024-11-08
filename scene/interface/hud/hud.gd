extends Control

@onready var time_label = %TimeLabel
var mouse_mode = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	time_label.text = "Time of day: " + TimeManager.get_time_of_day_str()

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_home"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
