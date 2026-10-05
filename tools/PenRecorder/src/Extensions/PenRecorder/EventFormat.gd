extends RefCounted


static func header(take: int, button_area: Rect2) -> Dictionary:
	var camera = Global.camera
	return {
		"header": true,
		"take": take,
		"pixelorama_version": str(ProjectSettings.get_setting("application/config/version", "")),
		"godot": Engine.get_version_info().get("string", ""),
		"os": OS.get_name(),
		"model": OS.get_model_name(),
		"window_size": _pair(Engine.get_main_loop().root.get_visible_rect().size),
		"record_button_rect": [_pair(button_area.position), _pair(button_area.size)],
		"canvas_container_rect": [_pair(Global.main_viewport.global_position), _pair(Global.main_viewport.size)],
		"camera_zoom": _pair(camera.zoom),
		"camera_offset": _pair(camera.offset),
		"camera_rotation": camera.camera_angle,
		"project_size": _pair(Global.current_project.size),
		"left_tool": str(Tools.get_tool(MOUSE_BUTTON_LEFT).tool_node.name),
		"right_tool": str(Tools.get_tool(MOUSE_BUTTON_RIGHT).tool_node.name),
	}


static func event(input: InputEvent, msec: float) -> Dictionary:
	var entry := {"t": snappedf(msec, 0.01), "type": input.get_class()}
	if input is InputEventMouseButton:
		entry.merge({"b": input.button_index, "p": input.pressed, "m": input.button_mask, "pos": _pair(input.position), "dbl": input.double_click})
	elif input is InputEventMouseMotion:
		entry.merge({"m": input.button_mask, "pos": _pair(input.position), "rel": _pair(input.relative), "pr": snappedf(input.pressure, 0.001), "inv": input.pen_inverted, "tilt": _pair(input.tilt)})
	elif input is InputEventScreenTouch:
		entry.merge({"i": input.index, "p": input.pressed, "pos": _pair(input.position), "cancel": input.canceled})
	elif input is InputEventScreenDrag:
		entry.merge({"i": input.index, "pos": _pair(input.position), "rel": _pair(input.relative)})
	elif input is InputEventMagnifyGesture:
		entry.merge({"f": snappedf(input.factor, 0.0001), "pos": _pair(input.position)})
	elif input is InputEventPanGesture:
		entry.merge({"delta": _pair(input.delta), "pos": _pair(input.position)})
	elif input is InputEventKey:
		entry.merge({"key": input.as_text_keycode(), "p": input.pressed, "echo": input.echo})
	else:
		entry["text"] = input.as_text()
	return entry


static func _pair(value: Vector2) -> Array:
	return [snappedf(value.x, 0.01), snappedf(value.y, 0.01)]
