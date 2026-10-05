extends RefCounted

const ROTATION_SNAP := deg_to_rad(5.0)
const RIGHT_ANGLE := PI / 2.0

var _rotation_start := 0.0


func undo() -> void:
	Global.current_project.commit_undo()


func redo() -> void:
	Global.current_project.commit_redo()


func fit_view() -> void:
	Global.camera.camera_angle = 0.0
	Global.camera.fit_to_frame(Global.current_project.size)


func move_view(screen_delta: Vector2) -> void:
	var camera = Global.camera
	camera.offset -= screen_delta.rotated(camera.camera_angle) / camera.zoom
	camera.update_transparent_checker_offset()


func begin_rotation() -> void:
	_rotation_start = Global.camera.camera_angle


func rotate_view(screen_angle: float, pivot: Vector2) -> void:
	var camera = Global.camera
	var old_angle: float = camera.camera_angle
	var new_angle := _snapped_angle(_rotation_start - screen_angle)
	var view_center: Vector2 = Global.main_viewport.get_global_rect().get_center()
	var from_center: Vector2 = (pivot - view_center) / camera.zoom
	camera.offset += from_center.rotated(old_angle) - from_center.rotated(new_angle)
	camera.camera_angle = new_angle


func use_tool_once(tool_name: String, pixel: Vector2i) -> void:
	cancel_active_stroke()
	Tools.quick_assign_tool(tool_name, MOUSE_BUTTON_LEFT)
	for pressed in [true, false]:
		Tools.handle_draw(pixel, _left_click(pressed))
	Tools.quick_assign_tool_revert(MOUSE_BUTTON_LEFT)


func cancel_active_stroke() -> void:
	if Tools.active_button == -1:
		return
	Tools.get_tool(Tools.active_button).tool_node.cancel_tool()
	Tools.active_button = -1
	Global.canvas.update_selected_cels_textures()
	Global.canvas.queue_redraw()


func is_over_canvas(position: Vector2) -> bool:
	if not Global.can_draw:
		return false
	var container: Control = Global.main_viewport
	return container.is_visible_in_tree() and container.get_global_rect().has_point(position)


func _left_click(pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	return event


func _snapped_angle(angle: float) -> float:
	var nearest_right_angle := roundf(angle / RIGHT_ANGLE) * RIGHT_ANGLE
	return nearest_right_angle if absf(angle - nearest_right_angle) < ROTATION_SNAP else angle
