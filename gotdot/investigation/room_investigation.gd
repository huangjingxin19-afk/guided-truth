extends Node

const EvidenceEntry = preload("res://investigation/evidence_entry.gd")
const InvestigationHud = preload("res://ui/investigation_hud.gd")

@export var hud: InvestigationHud
@export var walk_hint: Label
@export var stand_hint: Line2D


func _ready() -> void:
	_show_walk_hint()


func show_approach_hint(position: Vector2, message: String) -> void:
	if hud.is_open():
		return

	walk_hint.text = message
	stand_hint.global_position = position
	stand_hint.show()


func inspect(entry: EvidenceEntry) -> void:
	if hud.is_open():
		return

	_show_walk_hint()
	stand_hint.hide()
	InvestigationLog.record(entry)
	hud.show_evidence(entry)


func open_notebook() -> void:
	hud.show_notebook(InvestigationLog.entries())


func _show_walk_hint() -> void:
	walk_hint.text = "拖动摇杆或点击地面移动" if hud.uses_touch_controls() else "点击地面移动"
