extends Node

signal tapped(finger_count: int)
signal held(finger_count: int)
signal twist_began
signal twisted(total_angle: float, pivot: Vector2)

const Settings := preload("res://src/Extensions/TabletKit/core/Settings.gd")
const FingerPair := preload("res://src/Extensions/TabletKit/features/FingerPair.gd")
const PenActivity := preload("res://src/Extensions/TabletKit/core/PenActivity.gd")
const CanvasActions := preload("res://src/Extensions/TabletKit/core/CanvasActions.gd")
const MIN_FINGERS := 2
const TAP_MAX_MSEC := 350
const TAP_MAX_PAN := 8.0
const TAP_MAX_ZOOM := 0.15
const DRAG_MAX_TRAVEL := 24.0
const HOLD_MAX_PAN := 3.0
const HOLD_MAX_ZOOM := 0.05
const HOLD_START_MSEC := 700
const HOLD_FIRST_INTERVAL_MSEC := 400
const HOLD_MIN_INTERVAL_MSEC := 150
const HOLD_ACCELERATION_MSEC := 30
const HOLD_MAX_LANDING_GAP_MSEC := 200
const TWIST_DEAD_ZONE := deg_to_rad(10.0)
const TWIST_MAX_SCALE_CHANGE := 0.25
const TWIST_MIN_DISTANCE := 150.0

var settings: Settings
var pair: FingerPair
var pen: PenActivity
var actions: CanvasActions
var _starts := {}
var _most_fingers := 0
var _started_msec := 0
var _dragged := false
var _pan_travel := 0.0
var _zoom_log := 0.0
var _spoiled := false
var _landed_together := false
var _hold_repeats := 0
var _next_hold_msec := 0
var _twist_touch_id := -1
var _twist_reference := 0.0
var _twist_origin := 0.0
var _twisting := false
var _pinch_locked := false
var _off_canvas := false


func _ready() -> void:
	set_process(false)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag:
		_on_drag(event)
	elif event is InputEventGesture:
		_on_gesture(event)


func _process(_delta: float) -> void:
	if pen.is_active():
		_spoiled = true
	_update_twist()
	_update_hold()


func _on_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _starts.is_empty():
			_begin()
			_off_canvas = not actions.is_over_canvas(event.position)
		_starts[event.index] = event.position
		_most_fingers = maxi(_most_fingers, _starts.size())
		if _starts.size() == MIN_FINGERS:
			_landed_together = Time.get_ticks_msec() - _started_msec <= HOLD_MAX_LANDING_GAP_MSEC
		return
	_starts.erase(event.index)
	if _starts.is_empty():
		_end()


func _on_drag(event: InputEventScreenDrag) -> void:
	if _starts.has(event.index) and event.position.distance_to(_starts[event.index]) > DRAG_MAX_TRAVEL:
		_dragged = true


func _on_gesture(event: InputEventGesture) -> void:
	if _spoiled or _starts.size() < MIN_FINGERS:
		get_viewport().set_input_as_handled()
	elif event is InputEventPanGesture:
		_pan_travel += event.delta.length()
	elif event is InputEventMagnifyGesture:
		_zoom_log += log(event.factor)


func _begin() -> void:
	_most_fingers = 0
	_started_msec = Time.get_ticks_msec()
	_dragged = false
	_pan_travel = 0.0
	_zoom_log = 0.0
	_spoiled = pen.is_active()
	_landed_together = false
	_hold_repeats = 0
	_next_hold_msec = 0
	_twisting = false
	set_process(true)


func _end() -> void:
	set_process(false)
	var quick := Time.get_ticks_msec() - _started_msec <= TAP_MAX_MSEC
	var still := not _dragged and _pan_travel <= TAP_MAX_PAN and absf(_zoom_log) <= TAP_MAX_ZOOM
	if quick and still and not _spoiled and not _off_canvas and not _twisting and _hold_repeats == 0 and _most_fingers >= MIN_FINGERS:
		tapped.emit(_most_fingers)


func _update_hold() -> void:
	if _starts.size() < MIN_FINGERS or _spoiled or _off_canvas or not _landed_together or _twisting or not _held_still():
		return
	var now := Time.get_ticks_msec()
	if now - _started_msec < HOLD_START_MSEC or now < _next_hold_msec:
		return
	held.emit(_starts.size())
	_hold_repeats += 1
	var interval := HOLD_FIRST_INTERVAL_MSEC - HOLD_ACCELERATION_MSEC * _hold_repeats
	_next_hold_msec = now + maxi(HOLD_MIN_INTERVAL_MSEC, interval)


func _held_still() -> bool:
	return not _dragged and _pan_travel <= HOLD_MAX_PAN and absf(_zoom_log) <= HOLD_MAX_ZOOM


func _update_twist() -> void:
	if not _can_twist():
		return
	if pair.touch_id != _twist_touch_id:
		_twist_touch_id = pair.touch_id
		_twist_reference = pair.angle
		_twisting = false
		_pinch_locked = false
		return
	if not _twisting:
		if _pinch_locked or absf(angle_difference(_twist_reference, pair.angle)) < TWIST_DEAD_ZONE:
			return
		if _looks_like_pinch():
			_pinch_locked = true
			return
		_twisting = true
		_twist_origin = pair.angle
		twist_began.emit()
	var pivot := get_viewport().get_final_transform().affine_inverse() * pair.midpoint
	twisted.emit(angle_difference(_twist_origin, pair.angle), pivot)


func _looks_like_pinch() -> bool:
	if pair.distance < TWIST_MIN_DISTANCE or pair.start_distance <= 0.0:
		return true
	return absf(pair.distance / pair.start_distance - 1.0) > TWIST_MAX_SCALE_CHANGE


func _can_twist() -> bool:
	return (
		settings.value("two_finger_rotate")
		and pair != null
		and pair.is_installed()
		and pair.active
		and _starts.size() == MIN_FINGERS
		and not _spoiled
		and not _off_canvas
	)
