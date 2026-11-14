extends Node2D


func _ready() -> void:
	ChapterOne.progress_changed.connect(_refresh)
	ChapterOne.visit_corridor()
	_refresh()


func _refresh() -> void:
	$ChapterStatus.text = ChapterOne.story_time() + "  ·  " + ChapterOne.objective()
	$Investigation/SealPoint.disabled = not ChapterOne.commission_accepted
	$ArrivalHint.text = "门内灯亮了一截。『嗒、拖、嗒』。正门仍锁着。" if not InvestigationLog.has_entry(ChapterOne.SEAL.id) else "编号纸条仍完整贴着。可回前台重看委托和便笺。"


func _on_seal_inspected(_entry: Resource) -> void:
	if ChapterOne.inspect_seal():
		$Investigation.inspect(ChapterOne.SEAL)
