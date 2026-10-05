extends Node

const DIR := "res://src/Extensions/PenRecorder/"
const Recorder := preload(DIR + "Recorder.gd")
const TakeStorage := preload(DIR + "TakeStorage.gd")
const RecordButton := preload(DIR + "RecordButton.gd")
const MENU_LABEL := "Pen Recorder: start / stop"

var _recorder := Recorder.new()
var _storage := TakeStorage.new()
var _button := RecordButton.new()
var _menu_item := -1


func _enter_tree() -> void:
	_recorder.name = "PenRecorder"
	_button.name = "PenRecorderButton"
	_button.toggled_recording.connect(_toggle)
	_recorder.event_recorded.connect(_button.show_progress)
	for node in [_recorder, _button]:
		get_tree().root.add_child.call_deferred(node)
	_menu_item = ExtensionsApi.menu.add_menu_item(ExtensionsApi.menu.EDIT, MENU_LABEL, self)


func _exit_tree() -> void:
	ExtensionsApi.menu.remove_menu_item(ExtensionsApi.menu.EDIT, _menu_item)
	for node in [_recorder, _button]:
		if is_instance_valid(node):
			node.queue_free()


func menu_item_clicked() -> void:
	_toggle()


func _toggle() -> void:
	if _recorder.recording:
		_stop()
	else:
		_start()


func _start() -> void:
	var take := _storage.next_take_number()
	_recorder.start(take, _button.area())
	_button.show_recording(take)


func _stop() -> void:
	var lines := _recorder.stop(_button.area())
	var saved_to := _storage.save(_recorder.take, lines)
	_button.show_saved(_recorder.take, lines.size() - 1, saved_to)
