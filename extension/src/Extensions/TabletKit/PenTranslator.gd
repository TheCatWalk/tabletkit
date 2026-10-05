extends Node

signal held_button_changed(button: MouseButton)

const InputSender := preload("res://src/Extensions/TabletKit/InputSender.gd")

var held_button := MOUSE_BUTTON_NONE


func _input(event: InputEvent) -> void:
	if InputSender.is_sent(event) or event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if event is InputEventMouseButton:
		_translate_button(event)
	elif event is InputEventMouseMotion:
		_translate_motion(event)


func _translate_button(event: InputEventMouseButton) -> void:
	if event.button_index not in [MOUSE_BUTTON_NONE, MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		return
	get_viewport().set_input_as_handled()
	if not event.pressed:
		_hold(MOUSE_BUTTON_NONE, event)
	elif event.button_index == MOUSE_BUTTON_NONE:
		_hold(MOUSE_BUTTON_RIGHT, event)
	else:
		_hold(event.button_index, event)


func _translate_motion(event: InputEventMouseMotion) -> void:
	var wanted := _button_for_motion(event)
	if wanted == held_button and event.button_mask == InputSender.mask_of(held_button):
		return
	get_viewport().set_input_as_handled()
	_hold(wanted, event)
	InputSender.send(get_viewport(), InputSender.with_mask(event, held_button))


func _button_for_motion(event: InputEventMouseMotion) -> MouseButton:
	if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		return MOUSE_BUTTON_LEFT
	if event.button_mask & MOUSE_BUTTON_MASK_RIGHT or event.pressure > 0.0:
		return MOUSE_BUTTON_RIGHT
	return MOUSE_BUTTON_NONE


func _hold(button: MouseButton, at: InputEventMouse) -> void:
	if button == held_button:
		return
	if held_button != MOUSE_BUTTON_NONE:
		InputSender.send(get_viewport(), InputSender.button_event(held_button, false, at))
	held_button = button
	if held_button != MOUSE_BUTTON_NONE:
		InputSender.send(get_viewport(), InputSender.button_event(held_button, true, at))
	held_button_changed.emit(held_button)
