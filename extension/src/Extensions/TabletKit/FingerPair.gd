extends RefCounted

const AndroidBridge := preload("res://src/Extensions/TabletKit/AndroidBridge.gd")
const LISTENER_INTERFACE := "android.view.View$OnTouchListener"
const TOOL_TYPE_FINGER := 1
const ENDING_ACTIONS := [1, 3, 6]

var active := false
var touch_id := 0
var angle := 0.0
var midpoint := Vector2.ZERO
var distance := 0.0
var start_distance := 0.0
var failure := ""
var _view = null
var _listener = null


func install(bridge: AndroidBridge) -> bool:
	if is_installed():
		return true
	var render_view = bridge.render_view()
	if render_view == null:
		failure = bridge.failure
		return false
	_listener = JavaClassWrapper.create_sam_callback(LISTENER_INTERFACE, _on_touch)
	if _listener == null:
		failure = "listener not created"
		return false
	_view = render_view.getView()
	_view.setOnTouchListener(_listener)
	return true


func uninstall() -> void:
	if _view != null:
		_view.setOnTouchListener(null)
	_view = null
	_listener = null
	active = false


func is_installed() -> bool:
	return _view != null


func _on_touch(_view_ref, event) -> bool:
	if event.getPointerCount() < 2 or event.getToolType(0) != TOOL_TYPE_FINGER:
		active = false
		return false
	var first := Vector2(event.getX(0), event.getY(0))
	var second := Vector2(event.getX(1), event.getY(1))
	distance = first.distance_to(second)
	angle = (second - first).angle()
	midpoint = (first + second) * 0.5
	var still_touching: bool = event.getActionMasked() not in ENDING_ACTIONS
	if still_touching and not active:
		touch_id += 1
		start_distance = distance
	active = still_touching
	return false
