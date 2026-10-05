extends "res://src/UI/Canvas/Indicators.gd"

const TOOL_MEMBERS := [
	"_brush", "_cursor", "_draw_line", "_line_start", "_line_end", "_indicator", "_polylines", "_line_polylines"
]


func _draw() -> void:
	if not Global.can_draw:
		return
	if Global.right_square_indicator_visible and not Global.single_tool_mode:
		_draw_tool_indicator(MOUSE_BUTTON_RIGHT, false)
	if Global.left_square_indicator_visible:
		_draw_tool_indicator(MOUSE_BUTTON_LEFT, true)


func _draw_tool_indicator(button: MouseButton, left: bool) -> void:
	var tool: BaseTool = Tools._slots[button].tool_node
	if tool is BaseDrawTool and _can_draw_smooth(tool):
		_draw_brush_outline(tool, Global.left_tool_color if left else Global.right_tool_color)
	else:
		tool.draw_indicator(left)


func _can_draw_smooth(tool: BaseDrawTool) -> bool:
	for member in TOOL_MEMBERS:
		if not member in tool:
			return false
	return not (
		tool._brush.type in BaseDrawTool.IMAGE_BRUSHES
		or Tools.is_placing_tiles()
		or Global.current_project.has_selection
		or Global.current_project.tiles.mode
	)


func _draw_brush_outline(tool: BaseDrawTool, color: Color) -> void:
	var pos := Vector2i(tool.snap_position(tool._cursor))
	if tool._draw_line:
		pos = Vector2i(tool._line_start).min(Vector2i(tool._line_end))
	pos -= tool._indicator.get_size() / 2
	var width := 1.0 / (Global.camera.zoom.x * get_window().content_scale_factor)
	draw_set_transform(pos)
	for line in tool._line_polylines if tool._draw_line else tool._polylines:
		draw_polyline(PackedVector2Array(line), color, width, true)
	draw_set_transform(Vector2.ZERO)
