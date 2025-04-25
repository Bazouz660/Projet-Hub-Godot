extends Control

@onready var time_label = %TimeLabel
@onready var inventory_hud := %Inventory as HumanoidInventoryHUD
var mouse_mode = null

func _ready() -> void:
	MultiplayerManager.active_player_loaded.connect(_set_stamina_hud)
	MultiplayerManager.active_player_loaded.connect(_set_health_hud)
	MultiplayerManager.active_player_loaded.connect(_set_inventory_hud)

func _set_stamina_hud(_id):
	%StaminaHUD.resources = MultiplayerManager.active_player.resources
	%StaminaHUD._setup()

func _set_health_hud(_id):
	%HealthHUD.resources = MultiplayerManager.active_player.resources
	%HealthHUD._setup()
	(%StaminaHUD.resources as HumanoidResources).gain_health(1000000)

func _set_inventory_hud(_id):
	inventory_hud.inventory = MultiplayerManager.active_player.resources.inventory
	inventory_hud.head_slot = MultiplayerManager.active_player.resources.head_slot
	inventory_hud.chest_slot = MultiplayerManager.active_player.resources.chest_slot
	inventory_hud.shirt_slot = MultiplayerManager.active_player.resources.shirt_slot
	inventory_hud.legs_slot = MultiplayerManager.active_player.resources.legs_slot
	inventory_hud.feet_slot = MultiplayerManager.active_player.resources.feet_slot
	inventory_hud.hands_slot = MultiplayerManager.active_player.resources.hands_slot
	inventory_hud.weapon_slot = MultiplayerManager.active_player.resources.weapon_slot
	inventory_hud.init()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	time_label.text = "Time of day: " + TimeManager.get_time_of_day_str()

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_home"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
