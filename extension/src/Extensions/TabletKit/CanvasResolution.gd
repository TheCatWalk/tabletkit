extends RefCounted

const OVERLAY_NAME := "TabletKitSharpCanvas"

var _source: SubViewport
var _container: SubViewportContainer
var _overlay: TextureRect
var _sharp: SubViewport
var _scale := 1.0


func install() -> bool:
	_source = Global.canvas.get_viewport() as SubViewport
	if _source == null or not _source.get_parent() is SubViewportContainer:
		return false
	_container = _source.get_parent()
	_scale = _container.get_window().content_scale_factor
	if _scale <= 1.0:
		return false
	_sharp = SubViewport.new()
	_sharp.world_2d = _source.world_2d
	_sharp.disable_3d = true
	_sharp.canvas_item_default_texture_filter = _source.canvas_item_default_texture_filter
	_sharp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sharp.gui_disable_input = true
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
	return true


func uninstall() -> void:
	if _overlay == null:
		return
	RenderingServer.frame_pre_draw.disconnect(_sync)
	if is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = null
	_sharp = null
	if is_instance_valid(_container) and _container.is_visible_in_tree():
		_source.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_scale_checker(1.0)
	_smooth_guides(false)


func _sync() -> void:
	if not is_instance_valid(_source) or not is_instance_valid(_sharp):
		return
	var size := Vector2i((Vector2(_source.size) * _scale).round())
	if _sharp.size != size:
		_sharp.size = size
	_sharp.transparent_bg = _source.transparent_bg
	_sharp.canvas_transform = Transform2D.IDENTITY.scaled(Vector2.ONE * _scale) * _source.canvas_transform
	_sharp.global_canvas_transform = _source.global_canvas_transform
	var visible := _container.is_visible_in_tree()
	_overlay.visible = visible
	_sharp.render_target_update_mode = (
		SubViewport.UPDATE_ALWAYS if visible else SubViewport.UPDATE_DISABLED
	)
	if _source.render_target_update_mode != SubViewport.UPDATE_DISABLED:
		_source.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_scale_checker(_scale)
	_smooth_guides(true)


func _scale_checker(factor: float) -> void:
	var checker := Global.transparent_checker
	if not is_instance_valid(checker):
		return
	var canvas_xform := Global.canvas.get_global_transform_with_canvas()
	checker.material.set_shader_parameter(&"size", Global.checker_size * factor)
	checker.material.set_shader_parameter(&"offset", canvas_xform.get_origin() * factor)
	checker.material.set_shader_parameter(&"scale", canvas_xform.get_scale() * factor)


func _smooth_guides(enabled: bool) -> void:
	for guide in Global.current_project.guides:
		if guide.antialiased != enabled:
			guide.antialiased = enabled
