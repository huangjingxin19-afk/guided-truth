extends Control

@onready var _actions: VBoxContainer = %Actions
@onready var _continue_button: Button = %ContinueButton
@onready var _new_game_button: Button = %NewGameButton
@onready var _confirmation: VBoxContainer = %Confirmation
@onready var _cancel_button: Button = %CancelButton
@onready var _notice: Label = %Notice

var _has_save := false
var _starting := false


func _ready() -> void:
	SaveGame.close_session()
	_refresh_checkpoint()
	_focus_actions()


func _refresh_checkpoint() -> void:
	var checkpoint := SaveGame.checkpoint_status()
	_has_save = checkpoint.has_save
	_continue_button.visible = checkpoint.can_continue
	_notice.text = checkpoint.notice
	_notice.visible = not _notice.text.is_empty()


func _focus_actions() -> void:
	if _continue_button.visible:
		_continue_button.grab_focus()
	else:
		_new_game_button.grab_focus()


func _on_new_game_pressed() -> void:
	if _has_save:
		_actions.hide()
		_confirmation.show()
		_cancel_button.grab_focus()
	else:
		_start_game(true)


func _on_cancel_pressed() -> void:
	_confirmation.hide()
	_actions.show()
	_focus_actions()


func _unhandled_input(event: InputEvent) -> void:
	if _confirmation.visible and event.is_action_pressed(&"ui_cancel"):
		_on_cancel_pressed()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST or not is_node_ready() or _starting:
		return
	if _confirmation.visible:
		_on_cancel_pressed()
	else:
		get_tree().quit()


func _start_game(new_game: bool) -> void:
	if not _starting:
		_starting = true
		_enter_investigation.call_deferred(new_game)


func _enter_investigation(new_game: bool) -> void:
	var entered := SaveGame.start_new_game() if new_game else SaveGame.continue_game()
	if entered:
		return
	_starting = false
	_refresh_checkpoint()
	if _notice.text.is_empty():
		_notice.text = "无法开始新调查。" if new_game else "无法继续调查。"
		_notice.show()
	_on_cancel_pressed()
