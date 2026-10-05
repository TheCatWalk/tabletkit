extends RefCounted

const CanvasSmoothing := preload("res://src/Extensions/TabletKit/features/CanvasSmoothing.gd")
const CanvasResolution := preload("res://src/Extensions/TabletKit/features/CanvasResolution.gd")

var _smoothing := CanvasSmoothing.new()
var _resolution := CanvasResolution.new()
var _active := false


func set_high_quality(enabled: bool) -> void:
	if enabled == _active:
		return
	_active = enabled
	if enabled:
		_smoothing.install()
		_resolution.install()
	else:
		_resolution.uninstall()
		_smoothing.uninstall()
