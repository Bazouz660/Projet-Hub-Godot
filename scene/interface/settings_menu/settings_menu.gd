extends Control

@onready var menu_manager := $".." as MenuManager

@export var environment: Environment

# Display settings
@export var setting_vsync: SettingEntry
@export var setting_framerate_limit: SettingEntry
@export var setting_window_mode: SettingEntry

# Graphics settings
@export var setting_shadow_quality: SettingEntry
@export var setting_ssao_quality: SettingEntry
@export var setting_ssil_quality: SettingEntry
@export var setting_volumetric_fog: SettingEntry
@export var setting_bloom: SettingEntry

# Audio settings
@export var setting_global_volume: SettingEntry
@export var setting_music_volume: SettingEntry
@export var setting_sfx_volume: SettingEntry

func _ready() -> void:
	# Init signals
	setting_vsync.setting_changed.connect(_on_vsync_changed)
	setting_framerate_limit.setting_changed.connect(_on_framerate_limit_changed)
	setting_window_mode.setting_changed.connect(_on_window_mode_changed)
	setting_shadow_quality.setting_changed.connect(_on_shadow_quality_changed)
	setting_ssao_quality.setting_changed.connect(_on_ssao_quality_changed)
	setting_ssil_quality.setting_changed.connect(_on_ssil_quality_changed)
	setting_volumetric_fog.setting_changed.connect(_on_volumetric_fog_changed)
	setting_bloom.setting_changed.connect(_on_bloom_changed)


	# Load settings from config file
	load_settings()

	# setting_global_volume.setting_changed.connect(AudioServer.set_bus_volume_db.bind(AudioServer.get_bus_index("Master"), setting_global_volume.value))
	# setting_music_volume.setting_changed.connect(AudioServer.set_bus_volume_db.bind(AudioServer.get_bus_index("Music"), setting_music_volume.value))
	# setting_sfx_volume.setting_changed.connect(AudioServer.set_bus_volume_db.bind(AudioServer.get_bus_index("SFX"), setting_sfx_volume.value))

	# Set initial values
	# setting_vsync.set_value(ProjectSettings.get_setting("display/window/vsync_mode"))
	# setting_framerate_limit.set_value(Engine.max_fps)
	# setting_window_mode.set_value(ProjectSettings.get_setting("display/window/window_mode"))
	# setting_shadow_quality.set_value(ProjectSettings.get_setting("rendering/lights_and_shadows/directional_shadow/size"))
	# setting_ssao_quality.set_value(ProjectSettings.get_setting("rendering/environment/ssao/quality"))
	# setting_ssil_quality.set_value(ProjectSettings.get_setting("rendering/environment/ssil/quality"))
	# setting_volumetric_fog.set_value(environment.volumetric_fog_enabled)
	# setting_global_volume.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))
	# setting_music_volume.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))
	# setting_sfx_volume.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))

	ProjectSettings.settings_changed.connect(_on_project_settings_changed)


func _on_back_button_pressed() -> void:
	if menu_manager and menu_manager is MenuManager:
		menu_manager.go_to_last_menu()


func _on_save_button_pressed() -> void:
	save_settings()
	print("Settings saved successfully.")


func _on_project_settings_changed() -> void:
	print("Project settings changed")


func _on_vsync_changed(value) -> void:
	if value == "Disabled":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	elif value == "Enabled":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	elif value == "Adaptive":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)
	elif value == "Mailbox":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_MAILBOX)
	else:
		print("Unknown VSync mode: ", value)


func _on_framerate_limit_changed(value) -> void:
	var limit := int(value)
	Engine.max_fps = limit


func _on_window_mode_changed(value) -> void:
	if value == "Windowed":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	elif value == "Fullscreen":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif value == "Exclusive fullscreen":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		print("Unknown window mode: ", value)


func _on_shadow_quality_changed(value) -> void:
	var resolution: int = 2048
	print("Shadow quality changed to: ", value)

	if value == "Lowest":
		resolution = 0
	elif value == "Low":
		resolution = 1024
	elif value == "Medium":
		resolution = 2048
	elif value == "High":
		resolution = 4096
	elif value == "Extreme":
		resolution = 8192
	else:
		print("Unknown shadow quality: ", value)

	if resolution <= 0:
		ProjectSettings.set_setting("global/shadows_enabled", false)
		return
	else:
		ProjectSettings.set_setting("global/shadows_enabled", true)

	RenderingServer.directional_shadow_atlas_set_size(resolution, true)


func _on_ssao_quality_changed(value) -> void:
	var quality: int = 0

	if value == "Lowest":
		quality = 0
	elif value == "Low":
		quality = 1
	elif value == "Medium":
		quality = 2
	elif value == "High":
		quality = 3
	elif value == "Extreme":
		quality = 4
	else:
		print("Unknown SSAO quality: ", value)

	if quality <= 0:
		environment.ssao_enabled = false
	else:
		environment.ssao_enabled = true

	ProjectSettings.set_setting("rendering/environment/ssao/quality", quality)


func _on_ssil_quality_changed(value) -> void:
	var quality: int = 0

	if value == "Lowest":
		quality = 0
	elif value == "Low":
		quality = 1
	elif value == "Medium":
		quality = 2
	elif value == "High":
		quality = 3
	elif value == "Extreme":
		quality = 4
	else:
		print("Unknown SSIL quality: ", value)

	if quality <= 0:
		environment.ssil_enabled = false
	else:
		environment.ssil_enabled = true

	ProjectSettings.set_setting("rendering/environment/ssil/quality", quality)


func _on_volumetric_fog_changed(value) -> void:
	environment.volumetric_fog_enabled = value

func _on_bloom_changed(value) -> void:
	environment.glow_enabled = value

func save_settings() -> void:
	# Save the settings to a custom config file
	var config := ConfigFile.new()
	config.set_value("display", "vsync_mode", setting_vsync.get_value())
	config.set_value("display", "framerate_limit", setting_framerate_limit.get_value())
	config.set_value("display", "window_mode", setting_window_mode.get_value())
	config.set_value("rendering/lights_and_shadows", "directional_shadow/size", setting_shadow_quality.get_value())
	config.set_value("rendering/environment", "ssao/quality", setting_ssao_quality.get_value())
	config.set_value("rendering/environment", "ssil/quality", setting_ssil_quality.get_value())
	config.set_value("rendering/environment", "volumetric_fog_enabled", setting_volumetric_fog.get_value())
	config.set_value("rendering/environment", "bloom_enabled", setting_bloom.get_value())
	var file_path := "user://settings.cfg"
	if config.save(file_path) == OK:
		print("Settings saved to ", file_path)
	else:
		print("Failed to save settings to ", file_path)


func load_settings() -> void:
	# Load the settings from a custom config file
	var config := ConfigFile.new()
	var file_path := "user://settings.cfg"
	if config.load(file_path) == OK:
		print("Settings loaded from ", file_path)
		setting_vsync.set_value(config.get_value("display", "vsync_mode", "Enabled"), true)
		setting_framerate_limit.set_value(config.get_value("display", "framerate_limit", 60), true)
		setting_window_mode.set_value(config.get_value("display", "window_mode", "Windowed"), true)
		setting_shadow_quality.set_value(config.get_value("rendering/lights_and_shadows", "directional_shadow/size", "Medium"), true)
		setting_ssao_quality.set_value(config.get_value("rendering/environment", "ssao/quality", "Medium"), true)
		setting_ssil_quality.set_value(config.get_value("rendering/environment", "ssil/quality", "Medium"), true)
		setting_volumetric_fog.set_value(config.get_value("rendering/environment", "volumetric_fog_enabled", true), true)
		setting_bloom.set_value(config.get_value("rendering/environment", "bloom_enabled", true), true)
	else:
		print("Failed to load settings from ", file_path)
