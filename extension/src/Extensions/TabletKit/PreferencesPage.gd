extends RefCounted

const PAGE_NAME := "Touch"
const DIALOG_NAME := "PreferencesDialog"
const INSERT_AFTER := "Tools"
const BACKUP_PAGE := "Backup"
const BACKUP_SECTION_NAME := "TabletKitSaveToFile"
const RestoreButton := preload("res://src/Extensions/TabletKit/SettingRestoreButton.gd")
const Settings := preload("res://src/Extensions/TabletKit/Settings.gd")
const OrientationLayouts := preload("res://src/Extensions/TabletKit/OrientationLayouts.gd")
const LONG_PRESS_TOOLS := [
	["None", ""],
	["Color Picker", "ColorPicker"],
	["Bucket", "Bucket"],
]
const DISPLAY_QUALITIES := [
	["Default", "default"],
	["High quality", "high"],
]
const FINGER_ACTIONS := [
	["Draw", "draw"],
	["Move canvas", "move"],
	["Eyedropper", "pick"],
	["Erase", "erase"],
	["Nothing", "none"],
]

var settings: Settings
var compatibility_report := ""
var _dialogs: Node
var _dialog: Node
var _page: VBoxContainer
var _backup_section: VBoxContainer
var _layout_options: Dictionary[String, OptionButton] = {}


func install() -> void:
	_dialogs = Global.control.get_node("Dialogs")
	var existing := _dialogs.get_node_or_null(DIALOG_NAME)
	if existing:
		_attach(existing)
	else:
		_dialogs.child_entered_tree.connect(_on_dialog_added)


func uninstall() -> void:
	if _dialogs and _dialogs.child_entered_tree.is_connected(_on_dialog_added):
		_dialogs.child_entered_tree.disconnect(_on_dialog_added)
	if not is_instance_valid(_dialog):
		return
	var pages: PackedStringArray = _dialog.content_list
	var index := pages.find(PAGE_NAME)
	if index != -1:
		pages.remove_at(index)
		_dialog.content_list = pages
	_page.queue_free()
	if is_instance_valid(_backup_section):
		_backup_section.queue_free()
	_layout_options.clear()
	_dialog = null


func _on_dialog_added(node: Node) -> void:
	if node.name != DIALOG_NAME:
		return
	_dialogs.child_entered_tree.disconnect(_on_dialog_added)
	node.ready.connect(_attach.bind(node), CONNECT_ONE_SHOT)


func _attach(dialog: Node) -> void:
	_dialog = dialog
	_page = _build_page()
	_dialog.right_side.add_child(_page)
	var pages: PackedStringArray = _dialog.content_list
	pages.insert(pages.find(INSERT_AFTER) + 1, PAGE_NAME)
	_dialog.content_list = pages
	_page.visibility_changed.connect(_refresh_layout_choices)
	var backup_page: Node = _dialog.right_side.get_node_or_null(BACKUP_PAGE)
	if backup_page:
		_backup_section = _build_backup_section()
		backup_page.add_child(_backup_section)


func _build_page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.name = PAGE_NAME
	page.visible = false
	var gestures := _add_section(page, "Gestures")
	_add_check(gestures, "Two finger tap undo", "two_finger_tap_undo")
	_add_check(gestures, "Three finger tap redo", "three_finger_tap_redo")
	_add_check(gestures, "Hold to repeat", "hold_repeats")
	_add_check(gestures, "Two finger rotate", "two_finger_rotate")
	var fingers := _add_section(page, "Fingers")
	_add_choice(fingers, "One finger", "finger_action", FINGER_ACTIONS)
	_add_check(fingers, "Double tap fits canvas", "double_tap_fits")
	var long_press := _add_section(page, "Pen long press")
	_add_choice(long_press, "Tool", "long_press_tool", LONG_PRESS_TOOLS)
	_add_slider(long_press, "Delay", "long_press_delay", [0.2, 2.0, 0.05], "s")
	_add_slider(long_press, "Movement limit", "long_press_movement_limit", [1.0, 30.0, 1.0], "px")
	var canvas := _add_section(page, "Canvas")
	_add_choice(canvas, "Display quality", "display_quality", DISPLAY_QUALITIES)
	var layouts := _add_section(page, "Layouts")
	_layout_options["layout_landscape"] = _add_choice(layouts, "Landscape", "layout_landscape", _layout_choices())
	_layout_options["layout_portrait"] = _add_choice(layouts, "Portrait", "layout_portrait", _layout_choices())
	var other := _add_section(page, "Other")
	_add_check(other, "Tool settings in top bar", "quick_tool_bar")
	_add_check(other, "Status line", "show_status_line")
	_add_info(other, "Compatibility", compatibility_report)
	return page


func _build_backup_section() -> VBoxContainer:
	var section := VBoxContainer.new()
	section.name = BACKUP_SECTION_NAME
	var grid := _add_section(section, "Save to file")
	_add_check(grid, "Save automatically", "autosave")
	_add_slider(grid, "Every", "autosave_seconds", [5.0, 600.0, 5.0], "s")
	return section


func _refresh_layout_choices() -> void:
	if not _page.visible:
		return
	var choices := _layout_choices()
	for key in _layout_options:
		var options := _layout_options[key]
		options.clear()
		for choice in choices:
			options.add_item(choice[0])
			options.set_item_metadata(options.item_count - 1, choice[1])
		options.select(_choice_index(choices, settings.value(key)))


func _add_info(grid: GridContainer, text: String, info: String) -> void:
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var value := Label.new()
	value.text = info
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(label)
	grid.add_child(Control.new())
	grid.add_child(value)


func _layout_choices() -> Array:
	var choices := [["Don't switch", ""]]
	for layout_name in OrientationLayouts.layout_names():
		choices.append([layout_name, layout_name])
	return choices


func _add_section(page: VBoxContainer, title: String) -> GridContainer:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 0)
	header.add_to_group(&"HeaderLabels")
	var label := Label.new()
	label.theme_type_variation = &"HeaderSmall"
	label.text = title
	var separator := HSeparator.new()
	separator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(label)
	header.add_child(separator)
	var grid := GridContainer.new()
	grid.columns = 3
	page.add_child(header)
	page.add_child(grid)
	return grid


func _add_check(grid: GridContainer, text: String, key: String) -> void:
	var box := CheckBox.new()
	box.text = "On"
	box.button_pressed = settings.value(key)
	var restore := _add_row(grid, text, key, box)
	box.toggled.connect(func(on: bool) -> void: _store(key, on, restore))
	restore.restore = func() -> void: box.button_pressed = settings.default_of(key)


func _add_slider(grid: GridContainer, text: String, key: String, range_values: Array, unit: String) -> void:
	var slider := ValueSlider.new()
	slider.min_value = range_values[0]
	slider.max_value = range_values[1]
	slider.step = range_values[2]
	slider.suffix = unit
	slider.value = settings.value(key)
	slider.nine_patch_stretch = true
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		slider.set_stretch_margin(side, 3)
	var restore := _add_row(grid, text, key, slider)
	slider.value_changed.connect(func(new_value: float) -> void: _store(key, new_value, restore))
	restore.restore = func() -> void: slider.value = settings.default_of(key)


func _add_choice(grid: GridContainer, text: String, key: String, choices: Array) -> OptionButton:
	var options := OptionButton.new()
	for choice in choices:
		options.add_item(choice[0])
		options.set_item_metadata(options.item_count - 1, choice[1])
	options.select(_choice_index(choices, settings.value(key)))
	var restore := _add_row(grid, text, key, options)
	options.item_selected.connect(
		func(index: int) -> void: _store(key, options.get_item_metadata(index), restore)
	)
	restore.restore = func() -> void:
		var default_value: String = settings.default_of(key)
		options.select(_choice_index(choices, default_value))
		_store(key, default_value, restore)
	return options


func _add_row(grid: GridContainer, text: String, key: String, control: Control) -> RestoreButton:
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var restore: RestoreButton = RestoreButton.new()
	restore.ready.connect(_refresh_restore.bind(restore, key), CONNECT_ONE_SHOT)
	grid.add_child(label)
	grid.add_child(restore)
	grid.add_child(control)
	return restore


func _store(key: String, new_value: Variant, restore: RestoreButton) -> void:
	settings.store(key, new_value)
	_refresh_restore(restore, key)


func _refresh_restore(restore: RestoreButton, key: String) -> void:
	restore.set_disabled_status(settings.value(key) == settings.default_of(key))


func _choice_index(choices: Array, value: String) -> int:
	for index in choices.size():
		if choices[index][1] == value:
			return index
	return 0
