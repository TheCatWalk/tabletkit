extends RefCounted

const OVERLAY_NAME := "TabletKitSharpCanvas"

var _source: SubViewport
var _container: SubViewportContainer
var _overlay: TextureRect
var _sharp: SubViewport
var _greyscale: ColorRect
var _source_update_mode := SubViewport.UPDATE_ALWAYS


func install() -> void:
	if _overlay != null:
		return
	_source = Global.canvas.get_viewport() as SubViewport
	if _source == null or not _source.get_parent() is SubViewportContainer:
		return
	_container = _source.get_parent()
	_source_update_mode = _source.render_target_update_mode
	_sharp = SubViewport.new()
	_sharp.world_2d = _source.world_2d
	_sharp.disable_3d = true
	_sharp.canvas_item_default_texture_filter = _source.canvas_item_default_texture_filter
	_sharp.gui_disable_input = true
	_add_greyscale_mirror()
	_overlay = TextureRect.new()
	_overlay.name = OVERLAY_NAME
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_overlay.stretch_mode = TextureRect.STRETCH_SCALE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_overlay.material = _container.material
	_overlay.add_child(_sharp)
	_container.add_child(_overlay)
	_overlay.texture = _sharp.get_texture()
	RenderingServer.frame_pre_draw.connect(_sync)
	_sync()


func uninstall() -> void:
	if _overlay == null:
		return
	RenderingServer.frame_pre_draw.disconnect(_sync)
	if is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = null
	_sharp = null
	_greyscale = null
	if is_instance_valid(_source):
		_source.render_target_update_mode = _source_update_mode
	_scale_checker(1.0)
	_smooth_guides(false)


func _add_greyscale_mirror() -> void:
	var original := _greyscale_source()
	if original == null:
		return
	var layer := CanvasLayer.new()
	_greyscale = ColorRect.new()
	_greyscale.material = original.material
	_greyscale.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_greyscale.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_greyscale)
	_sharp.add_child(layer)


func _greyscale_source() -> ColorRect:
	var top_bar := Global.top_menu_container
	if not "greyscale_vision" in top_bar:
		return null
	return top_bar.get("greyscale_vision") as ColorRect


func _sync() -> void:
	if not is_instance_valid(_source) or not is_instance_valid(_sharp):
		return
	var scale := _container.get_window().content_scale_factor
	var visible := _container.is_visible_in_tree()
	var active := visible and scale > 1.0
	_overlay.visible = active
	_sharp.render_target_update_mode = (
		SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
	)
	if visible:
		_source.render_target_update_mode = (
			SubViewport.UPDATE_DISABLED if active else _source_update_mode
		)
	if active:
		var size := Vector2i((Vector2(_source.size) * scale).round())
		if _sharp.size != size:
			_sharp.size = size
		_sharp.transparent_bg = _source.transparent_bg
		_sharp.canvas_transform = Transform2D.IDENTITY.scaled(Vector2.ONE * scale) * _source.canvas_transform
		_sharp.global_canvas_transform = _source.global_canvas_transform
		_sync_greyscale()
	_scale_checker(scale if active else 1.0)
	_smooth_guides(true)


func _sync_greyscale() -> void:
	var original := _greyscale_source()
	if is_instance_valid(_greyscale) and original != null:
		_greyscale.visible = original.visible


func _scale_checker(factor: float) -> void:
	var checker := Global.transparent_checker
	if not is_instance_valid(checker):
		return
	var canvas_xform := Global.canvas.get_global_transform_with_canvas()
	checker.material.set_shader_parameter(&"size", Global.checker_size * factor)
	checker.material.set_shader_parameter(&"offset", canvas_xform.get_origin() * factor)
	checker.material.set_shader_parameter(&"scale", canvas_xform.get_scale() * factor)


func _smooth_guides(enabled: bool) -> void:
	for project in Global.projects:
		for guide in project.guides:
			if guide.antialiased != enabled:
				guide.antialiased = enabled
