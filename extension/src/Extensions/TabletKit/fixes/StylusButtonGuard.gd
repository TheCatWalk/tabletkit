extends RefCounted

const AndroidBridge := preload("res://src/Extensions/TabletKit/core/AndroidBridge.gd")

const LISTENER_INTERFACE := "android.view.View$OnGenericMotionListener"
const ACTION_BUTTON_PRESS := 11
const ACTION_BUTTON_RELEASE := 12
const TOOL_TYPE_STYLUS := 2

var swallowed := 0
var failure := ""
var _view = null
var _listener = null


func install(bridge: AndroidBridge) -> bool:
	var render_view = bridge.render_view()
	if render_view == null:
		failure = bridge.failure
		return false
	_listener = JavaClassWrapper.create_sam_callback(LISTENER_INTERFACE, _on_generic_motion)
	if _listener == null:
		failure = "listener not created"
		return false
	_view = render_view.getView()
	_view.setOnGenericMotionListener(_listener)
	return true


func uninstall() -> void:
	if _view != null:
		_view.setOnGenericMotionListener(null)
	_view = null
	_listener = null


func is_installed() -> bool:
	return _view != null


func _on_generic_motion(_view_ref, event) -> bool:
	var action: int = event.getActionMasked()
	if action != ACTION_BUTTON_PRESS and action != ACTION_BUTTON_RELEASE:
		return false
	if event.getToolType(0) != TOOL_TYPE_STYLUS:
		return false
	swallowed += 1
	return true
