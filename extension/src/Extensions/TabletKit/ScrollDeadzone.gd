extends RefCounted

const SETTING := "gui/common/default_scroll_deadzone"
const DEADZONE := 10

var _original_default := 0
var _changed: Array[ScrollContainer] = []
var _installed := false


func install() -> void:
	if _installed:
		return
	_installed = true
	_original_default = ProjectSettings.get_setting(SETTING, 0)
	ProjectSettings.set_setting(SETTING, DEADZONE)
	var tree := Engine.get_main_loop() as SceneTree
	for node in tree.root.find_children("*", "ScrollContainer", true, false):
		_apply(node)
	tree.node_added.connect(_on_node_added)


func uninstall() -> void:
	if not _installed:
		return
	_installed = false
	ProjectSettings.set_setting(SETTING, _original_default)
	(Engine.get_main_loop() as SceneTree).node_added.disconnect(_on_node_added)
	for scroll in _changed:
		if is_instance_valid(scroll):
			scroll.scroll_deadzone = 0
	_changed.clear()


func _on_node_added(node: Node) -> void:
	if node is ScrollContainer and node.scroll_deadzone in [0, DEADZONE]:
		node.scroll_deadzone = DEADZONE
		_changed.append(node)


func _apply(scroll: ScrollContainer) -> void:
	if scroll.scroll_deadzone != 0:
		return
	scroll.scroll_deadzone = DEADZONE
	_changed.append(scroll)
