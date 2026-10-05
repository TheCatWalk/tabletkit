extends RefCounted

const CanvasSmoothing := preload("res://src/Extensions/TabletKit/CanvasSmoothing.gd")
const TOP_BAR_ROW := "MarginContainer/HBoxContainer"
const LAYOUT_MENU_MEMBERS := ["main_ui", "selected_layout", "layouts_submenu"]
const LAYOUT_MENU_METHODS := ["set_layout", "populate_layouts_submenu"]

var _missing: Dictionary[String, PackedStringArray] = {}


func check_all() -> void:
	_missing.clear()
	for check in _checks():
		if not check[2].call():
			if not _missing.has(check[0]):
				_missing[check[0]] = PackedStringArray()
			_missing[check[0]].append(check[1])


func allows(feature: String) -> bool:
	return not _missing.has(feature)


func report() -> String:
	if _missing.is_empty():
		return "All features available"
	var lines := PackedStringArray()
	for feature in _missing:
		lines.append("%s off: %s" % [feature, ", ".join(_missing[feature])])
	return "\n".join(lines)


func _checks() -> Array:
	return [
		["Display quality", "canvas shader", func() -> bool: return _shader_has(Global.canvas.material, CanvasSmoothing.LAYER_PATCH)],
		["Display quality", "checker shader", func() -> bool: return _shader_has(Global.transparent_checker.material, CanvasSmoothing.CHECKER_PATCH)],
		["Display quality", "canvas viewport", func() -> bool: return Global.canvas.get_viewport().get_parent() is SubViewportContainer],
		["Display quality", "brush outline", func() -> bool: return "indicators" in Global.canvas and "_slots" in Tools],
		["Top bar", "top bar row", func() -> bool: return Global.top_menu_container.get_node_or_null(TOP_BAR_ROW + "/MainMenuButton") != null],
		["Tool settings in top bar", "tool slots", func() -> bool: return "_slots" in Tools],
		["Layouts", "layout menu", _has_layout_menu],
		["Save to file", "save function", func() -> bool: return OpenSave.has_method("save_pxo_file") and "BACKUPS_DIRECTORY" in OpenSave],
		["Save to file", "stroke state", func() -> bool: return "active_button" in Tools and "show_notification_label" in Global],
		["Gestures", "canvas camera", func() -> bool: return "camera_angle" in Global.camera and "offset" in Global.camera],
	]


func _has_layout_menu() -> bool:
	var menu: Node = Global.top_menu_container
	for member in LAYOUT_MENU_MEMBERS:
		if not member in menu:
			return false
	for method in LAYOUT_MENU_METHODS:
		if not menu.has_method(method):
			return false
	return "layouts" in Global and "pixelorama_has_loaded" in Global


func _shader_has(material: Material, replacements: Dictionary) -> bool:
	if not material is ShaderMaterial or material.shader == null:
		return false
	var code: String = material.shader.code
	if code.contains("tablet_kit_"):
		return true
	for target in replacements:
		if not code.contains(target):
			return false
	return true
