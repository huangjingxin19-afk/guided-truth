extends Node2D


func _ready() -> void:
	ChapterOne.progress_changed.connect(_refresh)
	ChapterOne.visit_corridor()
	_refresh()


func _refresh() -> void:
	$ChapterStatus.text = ChapterOne.story_time() + "  ·  " + ChapterOne.objective()
	$Investigation/SealPoint.disabled = not ChapterOne.commission_accepted
	$Investigation/YardExit.disabled = not ChapterOne.commission_accepted
	if ChapterOne.can_enter_supply_door() or InvestigationLog.has_entry(ChapterOne.SEAL.id):
		$ArrivalHint.text = "正门仍锁着。右侧经外廊通往后院。"
	else:
		$ArrivalHint.text = "门内灯亮了一截。『嗒、拖、嗒』。正门仍锁着。"


func _on_seal_inspected(_entry: Resource) -> void:
	if ChapterOne.inspect_seal():
		$Investigation.inspect(ChapterOne.SEAL)
