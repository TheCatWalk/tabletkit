extends RefCounted

signal changed(key: String, value: Variant)

const SECTION := "tablet_kit"
const DEFAULTS := {
	"two_finger_tap_undo": true,
	"three_finger_tap_redo": true,
	"hold_repeats": true,
	"double_tap_fits": true,
	"two_finger_rotate": false,
	"display_quality": "high",
	"quick_tool_bar": true,
	"layout_landscape": "",
	"layout_portrait": "",
	"tablet_layouts_created": false,
	"autosave": false,
	"autosave_seconds": 30.0,
	"finger_action": "move",
	"long_press_tool": "ColorPicker",
	"long_press_delay": 0.6,
	"long_press_movement_limit": 6.0,
	"show_status_line": false,
	"right_tool_assigned": false,
}

var _values := DEFAULTS.duplicate()
var _config: ConfigFile


func load_from(config: ConfigFile) -> void:
	_config = config
	for key in DEFAULTS:
		_values[key] = config.get_value(SECTION, key, DEFAULTS[key])


func value(key: String) -> Variant:
	return _values[key]


func default_of(key: String) -> Variant:
	return DEFAULTS[key]


func store(key: String, new_value: Variant) -> void:
	if _values[key] == new_value:
		return
	_values[key] = new_value
	if _config:
		_config.set_value(SECTION, key, new_value)
	changed.emit(key, new_value)
