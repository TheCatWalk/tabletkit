extends Node

signal event_recorded(event_count: int)

const EventFormat := preload("res://src/Extensions/PenRecorder/EventFormat.gd")

var recording := false
var take := 0
var _lines := PackedStringArray()
var _started_usec := 0


func start(take_number: int, button_area: Rect2) -> void:
	take = take_number
	_lines = PackedStringArray([JSON.stringify(EventFormat.header(take, button_area))])
	_started_usec = Time.get_ticks_usec()
	recording = true


func stop(button_area: Rect2) -> PackedStringArray:
	recording = false
	_drop_trailing_taps(button_area.grow(8))
	return _lines


func _input(event: InputEvent) -> void:
	if not recording:
		return
	var msec := (Time.get_ticks_usec() - _started_usec) / 1000.0
	_lines.append(JSON.stringify(EventFormat.event(event, msec)))
	event_recorded.emit(_lines.size() - 1)


func _drop_trailing_taps(area: Rect2) -> void:
	while _lines.size() > 1:
		var last = JSON.parse_string(_lines[_lines.size() - 1])
		if not (last is Dictionary and last.get("pos", []).size() == 2):
			return
		if not area.has_point(Vector2(last.pos[0], last.pos[1])):
			return
		_lines.remove_at(_lines.size() - 1)
