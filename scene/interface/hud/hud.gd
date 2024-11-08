extends Control

func _ready() -> void:
	MultiplayerManager.active_player_loaded.connect(_set_stamina_hud)

func _set_stamina_hud():
	$StaminaHUD.stamina = MultiplayerManager.active_player.stamina
	$StaminaHUD._setup()
