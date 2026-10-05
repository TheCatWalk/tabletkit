extends RestoreDefaultButton

var restore: Callable


func _on_pressed() -> void:
	restore.call()
