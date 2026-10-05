extends RefCounted

const AFTER_LIFT_MSEC := 300

var _touching := false
var _lifted_msec := -AFTER_LIFT_MSEC


func on_held_button_changed(button: MouseButton) -> void:
	var touching := button != MOUSE_BUTTON_NONE
	if _touching and not touching:
		_lifted_msec = Time.get_ticks_msec()
	_touching = touching


func is_active() -> bool:
	return _touching or Time.get_ticks_msec() - _lifted_msec < AFTER_LIFT_MSEC
