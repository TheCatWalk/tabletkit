extends CanvasLayer

const Settings := preload("res://src/Extensions/TabletKit/Settings.gd")
const StylusButtonGuard := preload("res://src/Extensions/TabletKit/StylusButtonGuard.gd")
const InputHandlerTweaks := preload("res://src/Extensions/TabletKit/InputHandlerTweaks.gd")
const BUTTON_NAMES := {
	MOUSE_BUTTON_NONE: "-",
	MOUSE_BUTTON_LEFT: "pencil",
	MOUSE_BUTTON_RIGHT: "ERASER",
}

var version := ""
var settings: Settings
var guard: StylusButtonGuard
var tweaks: InputHandlerTweaks
var _held := MOUSE_BUTTON_NONE
var _label := Label.new()


func _ready() -> void:
	layer = 127
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", Color.YELLOW)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)
	_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_label.offset_top = -30
	_label.offset_left = 8
	add_child(_label)
	settings.changed.connect(_on_setting_changed)
	_show(settings.value("show_status_line"))


func _process(_delta: float) -> void:
	_label.text = "TabletKit %s   pen: %s   guard: %s   tweaks: %s" % [
		version, BUTTON_NAMES[_held], _guard_text(), _tweaks_text()]


func on_held_button_changed(button: MouseButton) -> void:
	_held = button


func _on_setting_changed(key: String, new_value: Variant) -> void:
	if key == "show_status_line":
		_show(new_value)


func _show(on: bool) -> void:
	visible = on
	set_process(on)


func _guard_text() -> String:
	if guard.is_installed():
		return "on (%d)" % guard.swallowed
	return "off, " + guard.failure


func _tweaks_text() -> String:
	return "on" if tweaks.is_installed() else "off, " + tweaks.failure
