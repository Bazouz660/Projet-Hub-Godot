@tool
extends Control
class_name SettingEntry

enum SettingType {
	BOOLEAN,
	INTEGER,
	FLOAT,
	STRING,
	ENUM,
	SLIDER
}

signal setting_changed(value)

@onready var container: Control = $HSplitContainer
@export var setting_name: String = "Setting Name":
	set(value):
		setting_name = value
		if label:
			label.text = setting_name

@export var setting_type: SettingType = SettingType.BOOLEAN

@export_group("Integer Settings")
@export var i_min_value: int = 0
@export var i_max_value: int = 100

@export_group("Float Settings")
@export var f_min_value: float = 0.0
@export var f_max_value: float = 100.0
@export var f_step: float = 0.1

@export_group("Enum Settings")
@export var enum_options: Array[String] = ["Option 1", "Option 2", "Option 3"]

@export_group("Slider Settings")
@export var slider_min_value: float = 0.0
@export var slider_max_value: float = 100.0
@export var slider_step: float = 1.0
@export var slider_value: float = 100.0
@export var slider_show_value: bool = true

@export_group("Default Values")
@export var default_bool: bool = false
@export var default_int: int = 0
@export var default_float: float = 0.0
@export var default_string: String = ""
@export var default_enum_index: int = 0

var current_value
var setting_control: Control
var label: Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_setup_setting()
	# Initialize with default value if no value is set
	if current_value == null:
		reset_to_default()

func _setup_setting() -> void:
	# Clear existing children
	for child in container.get_children():
		child.queue_free()

	# Create label
	label = Label.new()
	label.text = setting_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(label)

	# Create appropriate control based on type
	match setting_type:
		SettingType.BOOLEAN:
			setting_control = _create_boolean_setting()
		SettingType.INTEGER:
			setting_control = _create_integer_setting()
		SettingType.FLOAT:
			setting_control = _create_float_setting()
		SettingType.STRING:
			setting_control = _create_string_setting()
		SettingType.ENUM:
			setting_control = _create_enum_setting()
		SettingType.SLIDER:
			setting_control = _create_slider_setting()

	if setting_control:
		container.add_child(setting_control)
		_connect_signals()

func _connect_signals() -> void:
	match setting_type:
		SettingType.BOOLEAN:
			(setting_control as CheckBox).toggled.connect(_on_boolean_changed)
		SettingType.INTEGER, SettingType.FLOAT:
			(setting_control as SpinBox).value_changed.connect(_on_numeric_changed)
		SettingType.STRING:
			(setting_control as LineEdit).text_changed.connect(_on_string_changed)
		SettingType.ENUM:
			(setting_control as OptionButton).item_selected.connect(_on_enum_changed)
		SettingType.SLIDER:
			var slider = (setting_control as HBoxContainer).get_child(0) as HSlider
			slider.value_changed.connect(_on_slider_changed)

func _create_boolean_setting() -> Control:
	var checkbox = CheckBox.new()
	checkbox.size_flags_horizontal = Control.SIZE_SHRINK_END
	return checkbox

func _create_integer_setting() -> Control:
	var spin_box = SpinBox.new()
	spin_box.min_value = i_min_value
	spin_box.max_value = i_max_value
	spin_box.size_flags_horizontal = Control.SIZE_SHRINK_END
	return spin_box

func _create_float_setting() -> Control:
	var spin_box = SpinBox.new()
	spin_box.min_value = f_min_value
	spin_box.max_value = f_max_value
	spin_box.step = f_step
	spin_box.size_flags_horizontal = Control.SIZE_SHRINK_END
	return spin_box

func _create_string_setting() -> Control:
	var line_edit = LineEdit.new()
	line_edit.placeholder_text = setting_name
	line_edit.size_flags_horizontal = Control.SIZE_SHRINK_END
	return line_edit

func _create_enum_setting() -> Control:
	var option_button = OptionButton.new()
	option_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	for option in enum_options:
		option_button.add_item(str(option))
	return option_button

func _create_slider_setting() -> Control:
	var slider_container = HBoxContainer.new()
	slider_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var slider = HSlider.new()
	slider.min_value = slider_min_value
	slider.max_value = slider_max_value
	slider.step = slider_step
	slider.value = slider_value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider_container.add_child(slider)

	if slider_show_value:
		var value_label = Label.new()
		value_label.text = str(slider_value)
		value_label.size_flags_horizontal = Control.SIZE_SHRINK_END
		value_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		value_label.custom_minimum_size.x = 50 # Give it some minimum width
		value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slider_container.add_child(value_label)

	return slider_container

# Signal handlers
func _on_boolean_changed(value: bool) -> void:
	current_value = value
	setting_changed.emit(value)

func _on_numeric_changed(value: float) -> void:
	if setting_type == SettingType.INTEGER:
		current_value = int(value)
	else:
		current_value = value
	setting_changed.emit(current_value)

func _on_string_changed(value: String) -> void:
	current_value = value
	setting_changed.emit(value)

func _on_enum_changed(index: int) -> void:
	if index >= 0 and index < enum_options.size():
		current_value = enum_options[index]
		setting_changed.emit(current_value)

func _on_slider_changed(value: float) -> void:
	if setting_type == SettingType.SLIDER:
		current_value = value
		setting_changed.emit(value)

		# Update value label if it exists
		if slider_show_value and setting_control is HBoxContainer:
			var slider_container = setting_control as HBoxContainer
			if slider_container.get_child_count() > 1:
				var value_label = slider_container.get_child(1) as Label
				if value_label:
					value_label.text = str(value)

# Value management
func set_value(value, emit_signal: bool = false) -> void:
	current_value = value
	if not setting_control:
		return

	match setting_type:
		SettingType.BOOLEAN:
			if setting_control is CheckBox:
				(setting_control as CheckBox).button_pressed = bool(value)
		SettingType.INTEGER:
			if setting_control is SpinBox:
				(setting_control as SpinBox).value = int(value)
		SettingType.FLOAT:
			if setting_control is SpinBox:
				(setting_control as SpinBox).value = float(value)
		SettingType.STRING:
			if setting_control is LineEdit:
				(setting_control as LineEdit).text = str(value)
		SettingType.ENUM:
			if setting_control is OptionButton:
				var index = enum_options.find(value)
				if index >= 0:
					(setting_control as OptionButton).selected = index
		SettingType.SLIDER:
			if setting_control is HBoxContainer:
				var slider_container = setting_control as HBoxContainer
				var slider = slider_container.get_child(0) as HSlider
				if slider:
					slider.value = float(value)
				if slider_show_value and slider_container.get_child_count() > 1:
					var value_label = slider_container.get_child(1) as Label
					if value_label:
						value_label.text = str(value)
	if emit_signal:
		setting_changed.emit(current_value)

func get_value():
	return current_value

func get_setting_name() -> String:
	return setting_name

func set_setting_name(new_name: String) -> void:
	setting_name = new_name
	if label:
		label.text = setting_name

# Utility functions
func is_valid_value(value) -> bool:
	match setting_type:
		SettingType.BOOLEAN:
			return value is bool
		SettingType.INTEGER:
			return value is int and value >= i_min_value and value <= i_max_value
		SettingType.FLOAT:
			return (value is float or value is int) and value >= f_min_value and value <= f_max_value
		SettingType.STRING:
			return value is String
		SettingType.ENUM:
			return value in enum_options
		SettingType.SLIDER:
			return (value is float or value is int) and value >= slider_min_value and value <= slider_max_value
	return false

func reset_to_default() -> void:
	match setting_type:
		SettingType.BOOLEAN:
			set_value(default_bool)
		SettingType.INTEGER:
			set_value(default_int)
		SettingType.FLOAT:
			set_value(default_float)
		SettingType.STRING:
			set_value(default_string)
		SettingType.ENUM:
			if default_enum_index >= 0 and default_enum_index < enum_options.size():
				set_value(enum_options[default_enum_index])
			elif enum_options.size() > 0:
				set_value(enum_options[0])
		SettingType.SLIDER:
			set_value(slider_value)

func get_default_value():
	match setting_type:
		SettingType.BOOLEAN:
			return default_bool
		SettingType.INTEGER:
			return default_int
		SettingType.FLOAT:
			return default_float
		SettingType.STRING:
			return default_string
		SettingType.ENUM:
			if default_enum_index >= 0 and default_enum_index < enum_options.size():
				return enum_options[default_enum_index]
			elif enum_options.size() > 0:
				return enum_options[0]
		SettingType.SLIDER:
			return slider_value
	return null

# For updating the setting type at runtime (useful for editor)
func update_setting_type(new_type: SettingType) -> void:
	if setting_type != new_type:
		setting_type = new_type
		if is_inside_tree():
			_setup_setting()

func update_enum_options(new_options: Array) -> void:
	enum_options = new_options
	if setting_type == SettingType.ENUM and is_inside_tree():
		_setup_setting()

# Serialization for saving/loading settings
func to_dict() -> Dictionary:
	var dict = {
		"name": setting_name,
		"type": setting_type,
		"value": current_value,
		"default_value": get_default_value()
	}

	match setting_type:
		SettingType.INTEGER:
			dict["min_value"] = i_min_value
			dict["max_value"] = i_max_value
		SettingType.FLOAT:
			dict["min_value"] = f_min_value
			dict["max_value"] = f_max_value
			dict["step"] = f_step
		SettingType.ENUM:
			dict["enum_options"] = enum_options

	return dict

func from_dict(data: Dictionary) -> void:
	if data.has("name"):
		set_setting_name(data["name"])
	if data.has("type"):
		update_setting_type(data["type"])
	if data.has("value"):
		set_value(data["value"])
	if data.has("enum_options") and setting_type == SettingType.ENUM:
		update_enum_options(data["enum_options"])

# For debugging
func _to_string() -> String:
	return "SettingEntry(name='%s', type=%d, value=%s)" % [setting_name, setting_type, str(current_value)]