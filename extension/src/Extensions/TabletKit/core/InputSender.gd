extends RefCounted

const SENT_META := &"tablet_kit_sent"


static func is_sent(event: InputEvent) -> bool:
	return event.has_meta(SENT_META)


static func send(viewport: Viewport, event: InputEventMouse) -> void:
	var in_window_pixels: InputEventMouse = event.xformed_by(viewport.get_final_transform())
	in_window_pixels.global_position = in_window_pixels.position
	in_window_pixels.set_meta(SENT_META, true)
	Input.parse_input_event(in_window_pixels)


static func button_event(button: MouseButton, pressed: bool, at: InputEventMouse) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.device = at.device
	event.position = at.position
	event.button_index = button
	event.pressed = pressed
	event.button_mask = mask_of(button) if pressed else 0
	return event


static func with_mask(event: InputEventMouseMotion, button: MouseButton) -> InputEventMouseMotion:
	var copy: InputEventMouseMotion = event.duplicate()
	copy.button_mask = mask_of(button)
	return copy


static func mask_of(button: MouseButton) -> int:
	match button:
		MOUSE_BUTTON_LEFT:
			return MOUSE_BUTTON_MASK_LEFT
		MOUSE_BUTTON_RIGHT:
			return MOUSE_BUTTON_MASK_RIGHT
	return 0
