extends Node

const Settings := preload("res://src/Extensions/TabletKit/Settings.gd")
const RETRY_SECONDS := 2.0

var settings: Settings
var available := true
var _timer := Timer.new()


func _ready() -> void:
	_timer.one_shot = true
	_timer.timeout.connect(_on_timeout)
	add_child(_timer)
	settings.changed.connect(_on_setting_changed)
	_restart_timer()
	_tint_save_button(_enabled())


func _exit_tree() -> void:
	if settings.changed.is_connected(_on_setting_changed):
		settings.changed.disconnect(_on_setting_changed)
	_tint_save_button(false)


func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		if _enabled():
			save_changed_projects()


func save_changed_projects() -> bool:
	if Tools.active_button != -1:
		return false
	var notifications_were_shown := Global.show_notification_label
	Global.show_notification_label = false
	for project in Global.projects:
		if _should_save(project):
			OpenSave.save_pxo_file(project.save_path, false, false, project)
	Global.show_notification_label = notifications_were_shown
	return true


func _should_save(project: Project) -> bool:
	return (
		project.has_changed
		and not project.save_path.is_empty()
		and not project.save_path.begins_with(OpenSave.BACKUPS_DIRECTORY)
	)


func _on_timeout() -> void:
	if not _enabled():
		return
	if save_changed_projects():
		_restart_timer()
	else:
		_timer.start(RETRY_SECONDS)


func _on_setting_changed(key: String, _value: Variant) -> void:
	if key in ["autosave", "autosave_seconds"]:
		_restart_timer()
		_tint_save_button(_enabled())


func _enabled() -> bool:
	return available and settings != null and settings.value("autosave")


func _restart_timer() -> void:
	_timer.stop()
	if _enabled():
		_timer.start(settings.value("autosave_seconds"))


func _tint_save_button(enabled: bool) -> void:
	var button := Global.top_menu_container.find_child("Save", true, false) as Button
	if button == null or button.get_parent().name != "QuickAccessButtons":
		return
	for child in button.get_children():
		if child is TextureRect:
			child.self_modulate = Global.left_tool_color.lightened(0.2) if enabled else Color.WHITE
