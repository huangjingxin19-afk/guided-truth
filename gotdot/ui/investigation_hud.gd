extends CanvasLayer

const EvidenceEntry = preload("res://investigation/evidence_entry.gd")
const EvidenceComparison = preload("res://ui/evidence_comparison.gd")
const TouchJoystick = preload("res://ui/touch_joystick.gd")
const PauseMenu = preload("res://ui/pause_menu.gd")

signal notebook_requested
signal interaction_requested
signal movement_changed(direction: Vector2, engaged: bool)
signal overlay_changed(open: bool)

@onready var overlay: Control = $Overlay
@onready var _pause_button: Button = $PauseButton
@onready var _pause_menu: PauseMenu = $PauseMenu
@onready var interaction_button: Button = $InteractionButton
@onready var _joystick: TouchJoystick = $TouchJoystick
@onready var header: Label = %Header
@onready var close_button: Button = %CloseButton
@onready var notebook: ScrollContainer = %Notebook
@onready var notebook_list: VBoxContainer = %NotebookList
@onready var evidence: VBoxContainer = %Evidence
@onready var preview_container: Panel = %Preview
@onready var preview_anchor: Node2D = %PreviewAnchor
@onready var description: Label = %Description
@onready var evidence_action_button: Button = %EvidenceAction
@onready var presentation_slot: CenterContainer = %Presentation

var _preview: Node2D
var _comparison: EvidenceComparison
var _return_action := Callable()
var _evidence_action := Callable()


func _ready() -> void:
	_joystick.movement_changed.connect(movement_changed.emit)
	overlay.visibility_changed.connect(_on_overlay_visibility_changed)
	close_button.visibility_changed.connect(_update_pause_button)
	_pause_menu.visibility_changed.connect(_on_overlay_visibility_changed)
	_on_overlay_visibility_changed()


func uses_touch_controls() -> bool:
	return DisplayServer.is_touchscreen_available()


func _on_overlay_visibility_changed() -> void:
	var open := is_open()
	overlay_changed.emit(open)
	_joystick.visible = uses_touch_controls() and not open
	_update_pause_button()


func _update_pause_button() -> void:
	_pause_button.visible = not _pause_menu.visible and (not overlay.visible or not close_button.visible)


func is_open() -> bool:
	return overlay.visible or _pause_menu.visible


func _on_back_requested() -> void:
	if _pause_menu.visible:
		_pause_menu.resume()
	elif overlay.visible and close_button.visible:
		_on_close_pressed()
	elif not RoomTransition.is_changing:
		_pause_menu.open_menu()


func set_interaction_prompt(label: String) -> void:
	interaction_button.visible = not label.is_empty() and not is_open()
	if interaction_button.visible:
		interaction_button.text = label if uses_touch_controls() else "E  " + label


func _unhandled_input(event: InputEvent) -> void:
	if interaction_button.visible and event.is_action_pressed(&"interact"):
		_on_interaction_pressed()
		get_viewport().set_input_as_handled()


func _on_interaction_pressed() -> void:
	if not is_open() and interaction_button.visible:
		interaction_requested.emit()


func show_evidence(
	entry: EvidenceEntry, from_notebook := false, action_label := "", action := Callable()
) -> void:
	_return_action = _show_notebook_page if from_notebook else Callable()
	header.text = entry.title
	description.text = entry.description
	close_button.text = "返回笔记" if from_notebook else "关闭"
	close_button.show()
	_evidence_action = action if not from_notebook else Callable()
	evidence_action_button.text = action_label
	evidence_action_button.visible = _evidence_action.is_valid()
	if is_instance_valid(_preview):
		preview_anchor.remove_child(_preview)
		_preview.queue_free()
		_preview = null
	preview_container.visible = entry.preview != null
	if entry.preview != null:
		preview_anchor.scale = Vector2.ONE * entry.preview_scale
		_preview = entry.preview.instantiate()
		preview_anchor.add_child(_preview)
	notebook.hide()
	presentation_slot.hide()
	evidence.show()
	overlay.show()
	close_button.grab_focus()


func show_presentation(view: Control, title: String, closable := false) -> void:
	if view.get_parent() != presentation_slot:
		view.reparent(presentation_slot, false)
	_evidence_action = Callable()
	header.text = title
	_return_action = Callable()
	close_button.text = "关闭"
	close_button.visible = closable
	evidence.hide()
	notebook.hide()
	for child: Control in presentation_slot.get_children():
		child.visible = child == view
	presentation_slot.show()
	overlay.show()
	if closable:
		close_button.grab_focus()


func close_presentation() -> void:
	presentation_slot.hide()
	overlay.hide()


func show_notebook(entries: Array[EvidenceEntry], comparison_entries: Array[EvidenceEntry] = []) -> void:
	for child in notebook_list.get_children():
		notebook_list.remove_child(child)
		child.queue_free()

	if entries.is_empty():
		var message := Label.new()
		message.text = "还没有记录。"
		notebook_list.add_child(message)

	if comparison_entries.size() == 2:
		var compare := Button.new()
		compare.text = "对照高窗与桌后"
		compare.custom_minimum_size.y = 52.0
		compare.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		compare.pressed.connect(_open_comparison.bind(comparison_entries))
		notebook_list.add_child(compare)

	for entry in entries:
		var button := Button.new()
		button.text = entry.title
		button.custom_minimum_size.y = 52.0
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(show_evidence.bind(entry, true))
		notebook_list.add_child(button)

	_show_notebook_page()


func _open_comparison(entries: Array[EvidenceEntry]) -> void:
	if is_instance_valid(_comparison):
		presentation_slot.remove_child(_comparison)
		_comparison.queue_free()
	_comparison = EvidenceComparison.new()
	_comparison.setup(entries, preview_container.get_theme_stylebox("panel"))
	_comparison.entry_selected.connect(_enlarge_comparison_entry)
	presentation_slot.add_child(_comparison)
	_show_comparison()


func _show_comparison() -> void:
	show_presentation(_comparison, "对照高窗与桌后", true)
	_return_action = _show_notebook_page
	close_button.text = "返回笔记"


func _enlarge_comparison_entry(entry: EvidenceEntry) -> void:
	show_evidence(entry)
	_return_action = _show_comparison
	close_button.text = "返回对照"


func _show_notebook_page() -> void:
	_return_action = Callable()
	header.text = "笔记"
	close_button.text = "关闭"
	close_button.show()
	_evidence_action = Callable()
	evidence.hide()
	presentation_slot.hide()
	notebook.show()
	overlay.show()
	close_button.grab_focus()


func _on_notebook_pressed() -> void:
	if not is_open():
		notebook_requested.emit()


func _on_close_pressed() -> void:
	_evidence_action = Callable()
	if _return_action.is_valid():
		_return_action.call()
	else:
		overlay.hide()


func _on_evidence_action_pressed() -> void:
	if _evidence_action.is_valid():
		_evidence_action.call()
