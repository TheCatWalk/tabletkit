extends RefCounted

const WRAPPER_NAME := "TabletKitTopBar"

var _margin: MarginContainer
var _row: HBoxContainer
var _wrapper: HBoxContainer
var _scroll: ScrollContainer
var _pinned: HBoxContainer
var _strip: HBoxContainer
var _main_menu: Control
var _original_filters: Dictionary[Control, int] = {}
var _row_size_flags := 0


func install() -> void:
	if is_instance_valid(_wrapper):
		return
	_margin = Global.top_menu_container.get_node_or_null("MarginContainer") as MarginContainer
	_row = _margin.get_node_or_null("HBoxContainer") as HBoxContainer if _margin else null
	_main_menu = _row.get_node_or_null("MainMenuButton") as Control if _row else null
	if _main_menu == null:
		return
	_wrapper = HBoxContainer.new()
	_wrapper.name = WRAPPER_NAME
	_scroll = ScrollContainer.new()
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pinned = HBoxContainer.new()
	_strip = HBoxContainer.new()
	_wrapper.add_child(_pinned)
	_wrapper.add_child(_scroll)
	_margin.add_child(_wrapper)
	_margin.move_child(_wrapper, _row.get_index())
	_row.reparent(_scroll, false)
	_row_size_flags = _row.size_flags_horizontal
	_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_main_menu.reparent(_pinned, false)
	_pinned.add_child(_strip)
	_let_drags_through(_row)


func uninstall() -> void:
	if not is_instance_valid(_wrapper):
		return
	for control: Control in _original_filters:
		if is_instance_valid(control):
			control.mouse_filter = _original_filters[control]
	_original_filters.clear()
	_main_menu.reparent(_row, false)
	_row.move_child(_main_menu, 0)
	_row.reparent(_margin, false)
	_row.size_flags_horizontal = _row_size_flags
	_margin.move_child(_row, _wrapper.get_index())
	_wrapper.queue_free()
	_wrapper = null


func pinned() -> HBoxContainer:
	return _strip if is_instance_valid(_wrapper) else null


func _let_drags_through(node: Node) -> void:
	for child in node.get_children():
		var control := child as Control
		if control and control.mouse_filter == Control.MOUSE_FILTER_STOP and not control is Range:
			_original_filters[control] = control.mouse_filter
			control.mouse_filter = Control.MOUSE_FILTER_PASS
		_let_drags_through(child)
