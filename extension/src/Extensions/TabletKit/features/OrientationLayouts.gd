extends RefCounted

const Settings := preload("res://src/Extensions/TabletKit/core/Settings.gd")

var settings: Settings
var _portrait := false
var _installed := false


func install() -> void:
	if _installed:
		return
	_installed = true
	_portrait = _is_portrait()
	Global.control.get_viewport().size_changed.connect(_on_size_changed)


func uninstall() -> void:
	if not _installed:
		return
	_installed = false
	Global.control.get_viewport().size_changed.disconnect(_on_size_changed)


static func layout_names() -> PackedStringArray:
	var names := PackedStringArray()
	for layout in Global.layouts:
		names.append(layout.resource_path.get_file().get_basename())
	return names


func _on_size_changed() -> void:
	var portrait := _is_portrait()
	if portrait == _portrait:
		return
	_portrait = portrait
	_apply.call_deferred(settings.value("layout_portrait" if portrait else "layout_landscape"))


func _apply(layout_name: String) -> void:
	var index := layout_names().find(layout_name)
	if index == -1:
		return
	Global.top_menu_container.set_layout(index)


func _is_portrait() -> bool:
	var size := Global.control.get_viewport().get_visible_rect().size
	return size.y > size.x
