extends Node

signal long_pressed(canvas_pixel: Vector2i)

const Settings := preload("res://src/Extensions/TabletKit/core/Settings.gd")

var settings: Settings
var _pen_position := Vector2.ZERO
var _press_position := Vector2.ZERO
var _press_pixel := Vector2i.ZERO
var _pressed_msec := 0


func _ready() -> void:
	set_process(false)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		_pen_position = event.position
		if is_processing() and _moved_too_far():
			set_process(false)


func _process(_delta: float) -> void:
	var delay_msec := int(settings.value("long_press_delay") * 1000.0)
	if Time.get_ticks_msec() - _pressed_msec >= delay_msec:
		set_process(false)
		long_pressed.emit(_press_pixel)


func on_held_button_changed(button: MouseButton) -> void:
	var waiting: bool = button == MOUSE_BUTTON_LEFT and not settings.value("long_press_tool").is_empty()
	if waiting:
		_press_position = _pen_position
		_press_pixel = Vector2i(Global.canvas.current_pixel.floor())
		_pressed_msec = Time.get_ticks_msec()
	set_process(waiting)


func _moved_too_far() -> bool:
	return _pen_position.distance_to(_press_position) > settings.value("long_press_movement_limit")
