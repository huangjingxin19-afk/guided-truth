extends ColorRect

signal back_requested

@onready var _resume_button: Button = %ResumeButton
@onready var _save_button: Button = %SaveButton
@onready var _status: Label = %Status


func open_menu() -> void:
	_status.hide()
	_save_button.disabled = not SaveGame.is_session_open()
	show()
	get_tree().paused = true
	_resume_button.grab_focus()


func resume() -> void:
	hide()
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		back_requested.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_node_ready():
		back_requested.emit()


func _on_save_pressed() -> void:
	var result := SaveGame.save_now()
	_status.text = "已保存，从房间入口继续。" if result == OK else "保存失败，请重试。"
	_status.show()


func _on_return_pressed() -> void:
	if SaveGame.is_session_open() and SaveGame.save_now() != OK:
		_status.text = "保存失败。请重试后返回主菜单。"
		_status.show()
		return
	var tree := get_tree()
	if tree.change_scene_to_file("res://ui/main_menu.tscn") == OK:
		tree.paused = false
	else:
		_status.text = "无法打开主菜单。"
		_status.show()
