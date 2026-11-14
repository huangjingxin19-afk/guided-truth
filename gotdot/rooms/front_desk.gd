extends Node2D

@onready var _investigation = $Investigation
@onready var _hud = $InvestigationHud


func _ready() -> void:
	ChapterOne.progress_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	$ChapterStatus.text = ChapterOne.story_time() + "  ·  " + ChapterOne.objective()
	$Investigation/HeQingPoint.interaction_label = "重看委托" if ChapterOne.commission_accepted else "领取委托"
	$Investigation/CorridorExit.disabled = not ChapterOne.commission_accepted


func _on_he_qing_interacted() -> void:
	var first_time := not ChapterOne.commission_accepted
	ChapterOne.accept_commission()
	_investigation.clear_approach_hint()
	_hud.show_evidence(ChapterOne.COMMISSION, false, "展开周闻的便笺" if first_time else "查看器材便笺", _show_note)


func _show_note() -> void:
	_hud.show_evidence(ChapterOne.EQUIPMENT_NOTE)
