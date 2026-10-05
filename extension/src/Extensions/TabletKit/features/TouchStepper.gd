extends Control

const PADDING := 8.0
const DRAG_START := 6.0
const DRAG_PIXELS_FOR_FULL_RANGE := 240.0
const MIN_PIXELS_PER_STEP := 3.0
const CAPTION_SIZE := 10
const VALUE_SIZE := 14

var slider: Range
var _press_x := 0.0
var _press_value := 0.0
var _pressed := false
var _dragging := false


func _init(target: Range) -> void:
	slider = target
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE


func _ready() -> void:
	slider.value_changed.connect(_on_value_changed)


func _exit_tree() -> void:
	if is_instance_valid(slider) and slider.value_changed.is_connected(_on_value_changed):
		slider.value_changed.disconnect(_on_value_changed)


func _gui_input(event: InputEvent) -> void:
	if not is_instance_valid(slider):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressed = true
			_dragging = false
			_press_x = event.position.x
			_press_value = slider.value
		elif _pressed:
			_pressed = false
			if not _dragging:
				_step(-1 if event.position.x < size.x / 2.0 else 1)
		queue_redraw()
		accept_event()
	elif event is InputEventMouseMotion and _pressed:
		var distance: float = event.position.x - _press_x
		if not _dragging and absf(distance) >= DRAG_START:
			_dragging = true
		if _dragging:
			slider.value = _press_value + roundf(distance / _pixels_per_step()) * slider.step
		accept_event()


func _get_minimum_size() -> Vector2:
	if not is_instance_valid(slider):
		return Vector2.ZERO
	var font := get_theme_default_font()
	var caption := font.get_string_size(_caption(), HORIZONTAL_ALIGNMENT_LEFT, -1, CAPTION_SIZE).x
	var value := font.get_string_size(_widest_value_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, VALUE_SIZE).x
	return Vector2(maxf(caption, value) + PADDING * 2.0, 0)


func _draw() -> void:
	if not is_instance_valid(slider):
		return
	var color := get_theme_color("font_color", "Label")
	if _pressed:
		draw_rect(Rect2(Vector2.ZERO, size), Color(color, 0.08))
	var font := get_theme_default_font()
	_draw_centered(font, _caption(), CAPTION_SIZE, Color(color, 0.55), size.y * 0.42)
	_draw_centered(font, _value_text(), VALUE_SIZE, color, size.y * 0.86)


func _draw_centered(font: Font, text: String, font_size: int, color: Color, baseline: float) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, Vector2((size.x - width) / 2.0, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _caption() -> String:
	return String(slider.get("prefix")).trim_suffix(":")


func _value_text() -> String:
	return _format(slider.value)


func _widest_value_text() -> String:
	return _format(slider.max_value)


func _format(number: float) -> String:
	var text := str(int(number)) if slider.step >= 1.0 else str(snappedf(number, slider.step))
	return text + String(slider.get("suffix"))


func _step(direction: int) -> void:
	slider.value += slider.step * direction


func _pixels_per_step() -> float:
	var steps := maxf((slider.max_value - slider.min_value) / slider.step, 1.0)
	return maxf(DRAG_PIXELS_FOR_FULL_RANGE / steps, MIN_PIXELS_PER_STEP)


func _on_value_changed(_value: float) -> void:
	queue_redraw()
