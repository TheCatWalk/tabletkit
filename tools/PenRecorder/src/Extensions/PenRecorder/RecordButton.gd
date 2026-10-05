extends CanvasLayer

signal toggled_recording

const DRAG_THRESHOLD := 16.0
const RECORDING_COLOR := Color(1, 0.3, 0.3)

var _button := Button.new()
var _label := Label.new()
var _press_position := Vector2.ZERO
var _button_start := Vector2.ZERO
var _pressing := false
var _dragged := false
var _recording_since_usec := 0
var _take := 0


func _ready() -> void:
	layer = 128
	_button.focus_mode = Control.FOCUS_NONE
	_button.custom_minimum_size = Vector2(150, 56)
	_button.add_theme_font_size_override("font_size", 22)
	_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_button.offset_left = -166
	_button.offset_right = -16
	_button.offset_top = 40
	_button.offset_bottom = 96
	_button.pressed.connect(_on_pressed)
	_button.gui_input.connect(_on_button_input)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", RECORDING_COLOR)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 4)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_label.offset_left = -560
	_label.offset_right = -16
	_label.offset_top = 100
	_label.offset_bottom = 180
	add_child(_button)
	add_child(_label)
	_show_idle()


func area() -> Rect2:
	return _button.get_global_rect()


func show_recording(take: int) -> void:
	_take = take
	_recording_since_usec = Time.get_ticks_usec()
	_button.text = "■ STOP %d" % take
	_button.add_theme_color_override("font_color", RECORDING_COLOR)
	show_progress(0)


func show_progress(event_count: int) -> void:
	var seconds := (Time.get_ticks_usec() - _recording_since_usec) / 1_000_000.0
	_label.text = "● REC take %d   %.1f s   %d events" % [_take, seconds, event_count]


func show_saved(take: int, event_count: int, saved_to: String) -> void:
	_show_idle()
	_label.text = "Take %d saved: %d events\n%s" % [take, event_count, saved_to]


func _show_idle() -> void:
	_button.text = "● REC"
	_button.remove_theme_color_override("font_color")


func _on_pressed() -> void:
	if _dragged:
		_dragged = false
		return
	toggled_recording.emit()


func _on_button_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_pressing = event.pressed
		if event.pressed:
			_dragged = false
			_press_position = event.global_position
			_button_start = _button.global_position
	elif event is InputEventMouseMotion and _pressing:
		_dragged = _dragged or event.global_position.distance_to(_press_position) > DRAG_THRESHOLD
		if _dragged:
			_move_to(_button_start + event.global_position - _press_position)


func _move_to(target: Vector2) -> void:
	var size := _button.size
	var position := target.clamp(Vector2.ZERO, _button.get_viewport_rect().size - size)
	_button.global_position = position
	_label.global_position = Vector2(position.x + size.x - _label.size.x, position.y + size.y + 4)
