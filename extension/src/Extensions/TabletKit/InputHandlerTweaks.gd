extends RefCounted

const AndroidBridge := preload("res://src/Extensions/TabletKit/AndroidBridge.gd")

var failure := ""
var _handler = null
var _detector = null


func install(bridge: AndroidBridge) -> bool:
	var render_view = bridge.render_view()
	if render_view == null:
		failure = bridge.failure
		return false
	_handler = render_view.getInputHandler()
	_detector = bridge.private_field(_handler, "scaleGestureDetector")
	if _detector == null:
		failure = "zoom detector not found"
		_handler = null
		return false
	_detector.setStylusScaleEnabled(false)
	_handler.enableLongPress(false)
	return true


func uninstall() -> void:
	if _detector != null:
		_detector.setStylusScaleEnabled(true)
	if _handler != null:
		_handler.enableLongPress(true)
	_detector = null
	_handler = null


func is_installed() -> bool:
	return _detector != null
