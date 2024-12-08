extends Control

@onready var time_label = %TimeLabel
var mouse_mode = null

func _ready() -> void:
	MultiplayerManager.active_player_loaded.connect(_set_stamina_hud)
	MultiplayerManager.active_player_loaded.connect(_set_inventory_hud)

func _set_stamina_hud(_id):
	%StaminaHUD.resources = MultiplayerManager.active_player.resources
	%StaminaHUD._setup()

func _set_inventory_hud(_id):
	%Inventory.inventory_component = MultiplayerManager.active_player.inventory
	%Inventory._setup_inventory()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	time_label.text = "Time of day: " + TimeManager.get_time_of_day_str()

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_home"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
