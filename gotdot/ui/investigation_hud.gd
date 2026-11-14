extends CanvasLayer

const EvidenceEntry = preload("res://investigation/evidence_entry.gd")
const TouchJoystick = preload("res://ui/touch_joystick.gd")

signal notebook_requested
signal movement_changed(direction: Vector2, engaged: bool)
signal overlay_changed(open: bool)

@onready var overlay: Control = $Overlay
@onready var _joystick: TouchJoystick = $TouchJoystick
@onready var header: Label = %Header
@onready var close_button: Button = %CloseButton
@onready var notebook: ScrollContainer = %Notebook
@onready var notebook_list: VBoxContainer = %NotebookList
@onready var evidence: VBoxContainer = %Evidence
@onready var preview_container: Panel = %Preview
@onready var preview_anchor: Node2D = %PreviewAnchor
@onready var description: Label = %Description

var _preview: Node2D
var _return_to_notebook := false


func _ready() -> void:
	_joystick.movement_changed.connect(movement_changed.emit)
	overlay.visibility_changed.connect(_on_overlay_visibility_changed)
	_on_overlay_visibility_changed()


func uses_touch_controls() -> bool:
	return DisplayServer.is_touchscreen_available()


func _on_overlay_visibility_changed() -> void:
	var open := is_open()
	overlay_changed.emit(open)
	_joystick.visible = uses_touch_controls() and not open


func is_open() -> bool:
	return overlay.visible


func show_evidence(entry: EvidenceEntry, from_notebook := false) -> void:
	_return_to_notebook = from_notebook
	header.text = entry.title
	description.text = entry.description
	close_button.text = "返回笔记" if from_notebook else "关闭"
	if is_instance_valid(_preview):
		preview_anchor.remove_child(_preview)
		_preview.queue_free()
		_preview = null
	preview_container.visible = entry.preview != null
	if entry.preview != null:
		_preview = entry.preview.instantiate()
		preview_anchor.add_child(_preview)
	notebook.hide()
	evidence.show()
	overlay.show()
	close_button.grab_focus()


func show_notebook(entries: Array[EvidenceEntry]) -> void:
	for child in notebook_list.get_children():
		notebook_list.remove_child(child)
		child.queue_free()

	if entries.is_empty():
		var message := Label.new()
		message.text = "还没有记录。"
		notebook_list.add_child(message)

	for entry in entries:
		var button := Button.new()
		button.text = entry.title
		button.custom_minimum_size.y = 52.0
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(show_evidence.bind(entry, true))
		notebook_list.add_child(button)

	_show_notebook_page()


func _show_notebook_page() -> void:
	_return_to_notebook = false
	header.text = "笔记"
	close_button.text = "关闭"
	evidence.hide()
	notebook.show()
	overlay.show()
	close_button.grab_focus()


func _on_notebook_pressed() -> void:
	if not is_open():
		notebook_requested.emit()


func _on_close_pressed() -> void:
	if _return_to_notebook:
		_show_notebook_page()
	else:
		overlay.hide()
