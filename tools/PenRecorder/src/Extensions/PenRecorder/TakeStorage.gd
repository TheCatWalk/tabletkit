extends RefCounted

const FOLDER := "PenRecorder"
const LOG_PREFIX := "PENREC "


func next_take_number() -> int:
	var number := 1
	while _exists(number):
		number += 1
	return number


func save(take: int, lines: PackedStringArray) -> String:
	_print_to_log(take, lines)
	for folder in _folders():
		DirAccess.make_dir_recursive_absolute(folder)
		var path := folder.path_join(_file_name(take))
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file:
			file.store_string("\n".join(lines) + "\n")
			return ProjectSettings.globalize_path(path)
	return "not saved, see the Android log"


func _exists(take: int) -> bool:
	for folder in _folders():
		if FileAccess.file_exists(folder.path_join(_file_name(take))):
			return true
	return false


func _folders() -> PackedStringArray:
	var folders := PackedStringArray()
	var downloads := OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	if not downloads.is_empty():
		folders.append(downloads.path_join(FOLDER))
	folders.append("user://".path_join(FOLDER))
	return folders


func _file_name(take: int) -> String:
	return "take%d.jsonl" % take


func _print_to_log(take: int, lines: PackedStringArray) -> void:
	print(LOG_PREFIX + "BEGIN take%d" % take)
	for line in lines:
		print(LOG_PREFIX + line)
	print(LOG_PREFIX + "END take%d" % take)
