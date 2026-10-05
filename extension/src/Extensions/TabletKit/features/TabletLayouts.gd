extends RefCounted

const Settings := preload("res://src/Extensions/TabletKit/core/Settings.gd")
const MENU_MEMBERS := ["main_ui", "selected_layout", "layouts_submenu"]
const LANDSCAPE := "Tablet"
const PORTRAIT := "Tablet Portrait"
const SIDE_PANELS := [
	"Palettes",
	"Color Picker",
	"Left Tool Options",
	"Right Tool Options",
	"Global Tool Options",
	"Color Picker Sliders",
	"Reference Images",
	"Canvas Preview",
	"Recorder",
]
const HIDDEN := [
	"3D Object Tree",
	"Tiles",
	"Perspective Editor",
	"Second Canvas",
	"Canvas Preview",
	"Recorder",
	"Color Picker Sliders",
]
const H := DockableLayoutSplit.Direction.HORIZONTAL
const V := DockableLayoutSplit.Direction.VERTICAL

var settings: Settings


func install() -> void:
	if settings.value("tablet_layouts_created"):
		return
	if not Global.pixelorama_has_loaded:
		Global.pixelorama_opened.connect(install, CONNECT_ONE_SHOT | CONNECT_DEFERRED)
		return
	for member in MENU_MEMBERS:
		if not member in Global.top_menu_container:
			return
	settings.store("tablet_layouts_created", true)
	var added := false
	for layout_name in [LANDSCAPE, PORTRAIT]:
		if _exists(layout_name):
			continue
		var layout := _build(layout_name)
		var path := Global.LAYOUT_DIR.path_join(layout_name + ".tres")
		layout.resource_name = layout_name
		layout.resource_path = path
		if ResourceSaver.save(layout, path) != OK:
			continue
		layout.save_on_change = true
		Global.layouts.append(layout)
		added = true
	if added:
		_refresh_menu()


func _build(layout_name: String) -> DockableLayout:
	var tools := _panel(["Tools", "3D Object Tree", "Tiles"])
	var canvas := _panel(["Main Canvas", "Perspective Editor", "Second Canvas"])
	var side := _panel(SIDE_PANELS)
	var timeline := _panel(["Animation Timeline"])
	var layout := DockableLayout.new()
	if layout_name == PORTRAIT:
		layout.root = _split(V, 0.68, _split(H, 0.0, tools, canvas), _split(H, 0.5, side, timeline))
	else:
		layout.root = _split(H, 0.0, tools, _split(H, 0.74, canvas, _split(V, 0.36, side, timeline)))
	for panel_name in HIDDEN:
		layout.hidden_tabs[panel_name] = true
	return layout


func _exists(layout_name: String) -> bool:
	for layout in Global.layouts:
		if layout.resource_path.get_file().get_basename() == layout_name:
			return true
	return false


func _refresh_menu() -> void:
	var menu: Node = Global.top_menu_container
	var current: DockableLayout = menu.main_ui.layout
	Global.layouts.sort_custom(
		func(a: DockableLayout, b: DockableLayout): return a.resource_path.get_file() < b.resource_path.get_file()
	)
	menu.populate_layouts_submenu()
	var index := Global.layouts.find(current)
	if index == -1:
		return
	menu.selected_layout = index
	for i in Global.layouts.size():
		menu.layouts_submenu.set_item_checked(i, i == index)
	Global.config_cache.set_value("window", "layout", index)
	Global.config_cache.save(Global.CONFIG_PATH)


func _panel(names: Array) -> DockableLayoutPanel:
	var panel := DockableLayoutPanel.new()
	panel.names = PackedStringArray(names)
	return panel


func _split(direction: int, percent: float, first: DockableLayoutNode, second: DockableLayoutNode) -> DockableLayoutSplit:
	var split := DockableLayoutSplit.new()
	split.direction = direction
	split.percent = percent
	split.first = first
	split.second = second
	return split
