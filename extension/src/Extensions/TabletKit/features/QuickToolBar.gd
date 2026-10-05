extends RefCounted

const TouchStepper := preload("res://src/Extensions/TabletKit/features/TouchStepper.gd")
const TopBarScroll := preload("res://src/Extensions/TabletKit/fixes/TopBarScroll.gd")
const BAR_NAME := "TabletKitQuickTools"
const SLIDER_NAMES := ["BrushSize", "DensityValueSlider", "OpacitySlider", "AmountSlider"]
const SLOTS := [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]
const MARKER_SIZE := Vector2(2, 14)

var top_bar: TopBarScroll
var _bar: HBoxContainer
var _groups: Dictionary[int, HBoxContainer] = {}
var _shown: Dictionary[int, Array] = {}
var _tools: Dictionary[int, Node] = {}
var _candidates: Dictionary[int, Array] = {}


func install() -> void:
	if is_instance_valid(_bar):
		return
	var strip := top_bar.pinned()
	if strip == null or not "_slots" in Tools:
		return
	_bar = HBoxContainer.new()
	_bar.name = BAR_NAME
	_bar.add_theme_constant_override("separation", 10)
	for button in SLOTS:
		var group := HBoxContainer.new()
		group.add_theme_constant_override("separation", 2)
		_bar.add_child(group)
		_groups[button] = group
		_shown[button] = []
		_tools[button] = null
		_candidates[button] = []
	strip.add_child(_bar)
	RenderingServer.frame_pre_draw.connect(_sync)
	_sync()


func uninstall() -> void:
	if not is_instance_valid(_bar):
		return
	RenderingServer.frame_pre_draw.disconnect(_sync)
	_bar.queue_free()
	_bar = null
	_groups.clear()
	_shown.clear()
	_tools.clear()
	_candidates.clear()


func _sync() -> void:
	for button in SLOTS:
		var sliders := _visible_sliders(button)
		if sliders != _shown[button]:
			_shown[button] = sliders
			_rebuild(button, sliders)


func _visible_sliders(button: int) -> Array:
	var tool_node: Node = Tools._slots[button].tool_node
	if tool_node != _tools[button]:
		_tools[button] = tool_node
		_candidates[button] = _find_sliders(tool_node)
	return _candidates[button].filter(func(slider) -> bool: return is_instance_valid(slider) and slider.visible)


func _find_sliders(tool_node: Node) -> Array:
	var sliders := []
	if not is_instance_valid(tool_node):
		return sliders
	for slider_name in SLIDER_NAMES:
		var slider := tool_node.find_child(slider_name, true, false) as Range
		if slider:
			sliders.append(slider)
	return sliders


func _rebuild(button: int, sliders: Array) -> void:
	var group := _groups[button]
	for child in group.get_children():
		group.remove_child(child)
		child.queue_free()
	group.visible = not sliders.is_empty()
	if sliders.is_empty():
		return
	var marker := ColorRect.new()
	marker.color = Global.left_tool_color if button == MOUSE_BUTTON_LEFT else Global.right_tool_color
	marker.custom_minimum_size = MARKER_SIZE
	marker.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	group.add_child(marker)
	for slider in sliders:
		group.add_child(TouchStepper.new(slider))
