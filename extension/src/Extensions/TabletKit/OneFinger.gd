extends Node

signal double_tapped

const Settings := preload("res://src/Extensions/TabletKit/Settings.gd")
const CanvasActions := preload("res://src/Extensions/TabletKit/CanvasActions.gd")
const InputSender := preload("res://src/Extensions/TabletKit/InputSender.gd")
const PenActivity := preload("res://src/Extensions/TabletKit/PenActivity.gd")
const DRAW := "draw"
const MOVE := "move"
const PICK := "pick"
const ERASE := "erase"
const NONE := "none"
const PICK_TOOL := "ColorPicker"
const TAP_MAX_MSEC := 250
const TAP_MAX_TRAVEL := 24.0
const DOUBLE_TAP_MAX_GAP_MSEC := 350
const DOUBLE_TAP_MAX_DISTANCE := 60.0

var settings: Settings
var actions: CanvasActions
var pen: PenActivity
var _fingers := 0
var _had_more_fingers := false
var _on_canvas := false
var _picking := false
var _tap_start_msec := 0
var _tap_start_position := Vector2.ZERO
var _tap_moved := false
var _last_tap_msec := -DOUBLE_TAP_MAX_GAP_MSEC
var _last_tap_position := Vector2.ZERO


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag:
		_on_drag(event)
	elif event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		if not InputSender.is_sent(event):
			_on_finger_mouse(event)


func _mode() -> String:
	return settings.value("finger_action")


func _on_touch(event: InputEventScreenTouch) -> void:
	_fingers = maxi(0, _fingers + (1 if event.pressed else -1))
	if event.pressed and _fingers == 1:
		_begin_tap(event.position)
	if _fingers == 0:
		if not _had_more_fingers:
			_end_tap(event.position)
		_had_more_fingers = false
	elif _fingers > 1:
		_had_more_fingers = true
	if event.pressed and _fingers == 2 and not pen.is_active():
		actions.cancel_active_stroke()
		_stop_picking()


func _begin_tap(position: Vector2) -> void:
	_tap_start_msec = Time.get_ticks_msec()
	_tap_start_position = position
	_tap_moved = false


func _end_tap(position: Vector2) -> void:
	var now := Time.get_ticks_msec()
	var is_tap := not _tap_moved and now - _tap_start_msec <= TAP_MAX_MSEC
	if not is_tap or pen.is_active() or not _on_canvas or _mode() not in [MOVE, NONE]:
		_last_tap_msec = -DOUBLE_TAP_MAX_GAP_MSEC
		return
	var follows_last_tap := now - _last_tap_msec <= DOUBLE_TAP_MAX_GAP_MSEC
	if follows_last_tap and position.distance_to(_last_tap_position) <= DOUBLE_TAP_MAX_DISTANCE:
		_last_tap_msec = -DOUBLE_TAP_MAX_GAP_MSEC
		double_tapped.emit()
	else:
		_last_tap_msec = now
		_last_tap_position = position


func _on_drag(event: InputEventScreenDrag) -> void:
	if event.position.distance_to(_tap_start_position) > TAP_MAX_TRAVEL:
		_tap_moved = true
	if _fingers == 1 and not _had_more_fingers and _on_canvas and not pen.is_active() and _mode() == MOVE:
		actions.move_view(event.relative)


func _on_finger_mouse(event: InputEventMouse) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_canvas = actions.is_over_canvas(event.position)
	if pen.is_active():
		get_viewport().set_input_as_handled()
		return
	if not _on_canvas:
		return
	if _fingers > 1:
		get_viewport().set_input_as_handled()
		return
	match _mode():
		DRAW:
			pass
		PICK:
			_pick(event)
		ERASE:
			_erase(event)
		_:
			get_viewport().set_input_as_handled()


func _pick(event: InputEventMouse) -> void:
	if event is InputEventMouseButton and event.pressed:
		Tools.quick_assign_tool(PICK_TOOL, MOUSE_BUTTON_LEFT)
		_picking = true
	elif event is InputEventMouseButton:
		_stop_picking.call_deferred()


func _stop_picking() -> void:
	if _picking:
		_picking = false
		Tools.quick_assign_tool_revert(MOUSE_BUTTON_LEFT)


func _erase(event: InputEventMouse) -> void:
	get_viewport().set_input_as_handled()
	if event is InputEventMouseButton:
		InputSender.send(get_viewport(), InputSender.button_event(MOUSE_BUTTON_RIGHT, event.pressed, event))
	elif event is InputEventMouseMotion:
		InputSender.send(get_viewport(), InputSender.with_mask(event, MOUSE_BUTTON_RIGHT))
