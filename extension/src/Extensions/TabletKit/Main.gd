extends Node

const DIR := "res://src/Extensions/TabletKit/"
const RIGHT_TOOL := "Eraser"
const Settings := preload(DIR + "Settings.gd")
const CanvasActions := preload(DIR + "CanvasActions.gd")
const AndroidBridge := preload(DIR + "AndroidBridge.gd")
const StylusButtonGuard := preload(DIR + "StylusButtonGuard.gd")
const InputHandlerTweaks := preload(DIR + "InputHandlerTweaks.gd")
const PreferencesPage := preload(DIR + "PreferencesPage.gd")
const PenTranslator := preload(DIR + "PenTranslator.gd")
const PenLongPress := preload(DIR + "PenLongPress.gd")
const MultiTouchGestures := preload(DIR + "MultiTouchGestures.gd")
const FingerPair := preload(DIR + "FingerPair.gd")
const OneFinger := preload(DIR + "OneFinger.gd")
const StatusLine := preload(DIR + "StatusLine.gd")
const PenActivity := preload(DIR + "PenActivity.gd")
const CanvasQuality := preload(DIR + "CanvasQuality.gd")

var _settings := Settings.new()
var _actions := CanvasActions.new()
var _pen_activity := PenActivity.new()
var _bridge := AndroidBridge.new()
var _guard := StylusButtonGuard.new()
var _tweaks := InputHandlerTweaks.new()
var _page := PreferencesPage.new()
var _translator := PenTranslator.new()
var _long_press := PenLongPress.new()
var _gestures := MultiTouchGestures.new()
var _finger_pair := FingerPair.new()
var _one_finger := OneFinger.new()
var _status := StatusLine.new()
var _canvas_quality := CanvasQuality.new()


func _enter_tree() -> void:
	_settings.load_from(Global.config_cache)
	_configure()
	_connect_signals()
	for node in _input_nodes():
		node.name = "TabletKit" + node.get_script().resource_path.get_file().get_basename()
		get_tree().root.add_child.call_deferred(node)
	_setup.call_deferred()


func _exit_tree() -> void:
	if _app_is_quitting():
		return
	_guard.uninstall()
	_tweaks.uninstall()
	_finger_pair.uninstall()
	_canvas_quality.set_high_quality(false)
	_page.uninstall()
	for node in _input_nodes():
		node.queue_free()


func _app_is_quitting() -> bool:
	return not _translator.is_inside_tree()


func _configure() -> void:
	_gestures.pen = _pen_activity
	_one_finger.pen = _pen_activity
	_page.settings = _settings
	_long_press.settings = _settings
	_gestures.settings = _settings
	_gestures.pair = _finger_pair
	_one_finger.settings = _settings
	_one_finger.actions = _actions
	_status.settings = _settings
	_status.version = _read_version()
	_status.guard = _guard
	_status.tweaks = _tweaks


func _connect_signals() -> void:
	for listener in [_pen_activity, _long_press, _status]:
		_translator.held_button_changed.connect(listener.on_held_button_changed)
	_long_press.long_pressed.connect(_on_long_pressed)
	_gestures.tapped.connect(_on_tapped)
	_gestures.held.connect(_on_held)
	_one_finger.double_tapped.connect(_on_double_tapped)
	_gestures.twist_began.connect(_on_twist_began)
	_gestures.twisted.connect(_on_twisted)
	_settings.changed.connect(_on_setting_changed)


func _input_nodes() -> Array[Node]:
	return [_translator, _long_press, _gestures, _one_finger, _status]


func _setup() -> void:
	Global.single_tool_mode = false
	_assign_right_tool_once()
	_guard.install(_bridge)
	_tweaks.install(_bridge)
	_update_finger_pair()
	_update_canvas_quality()
	_page.install()


func _assign_right_tool_once() -> void:
	if _settings.value("right_tool_assigned"):
		return
	Tools.assign_tool(RIGHT_TOOL, MOUSE_BUTTON_RIGHT)
	_settings.store("right_tool_assigned", true)


func _on_tapped(finger_count: int) -> void:
	match finger_count:
		2 when _settings.value("two_finger_tap_undo"):
			_actions.undo()
		3 when _settings.value("three_finger_tap_redo"):
			_actions.redo()


func _on_held(finger_count: int) -> void:
	if not _settings.value("hold_repeats"):
		return
	match finger_count:
		2 when _settings.value("two_finger_tap_undo"):
			_actions.undo()
		3 when _settings.value("three_finger_tap_redo"):
			_actions.redo()


func _on_double_tapped() -> void:
	if _settings.value("double_tap_fits"):
		_actions.fit_view()


func _on_twist_began() -> void:
	_actions.begin_rotation()


func _on_twisted(total_angle: float, pivot: Vector2) -> void:
	_actions.rotate_view(total_angle, pivot)


func _on_setting_changed(key: String, _value: Variant) -> void:
	match key:
		"two_finger_rotate":
			_update_finger_pair()
		"display_quality":
			_update_canvas_quality()


func _update_finger_pair() -> void:
	if _settings.value("two_finger_rotate"):
		_finger_pair.install(_bridge)
	else:
		_finger_pair.uninstall()


func _update_canvas_quality() -> void:
	_canvas_quality.set_high_quality(_settings.value("display_quality") == "high")


func _on_long_pressed(canvas_pixel: Vector2i) -> void:
	_actions.use_tool_once(_settings.value("long_press_tool"), canvas_pixel)


func _read_version() -> String:
	var info = JSON.parse_string(FileAccess.get_file_as_string(DIR + "extension.json"))
	return info.get("version", "?") if info is Dictionary else "?"
