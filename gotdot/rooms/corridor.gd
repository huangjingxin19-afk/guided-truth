extends Node2D

const Case = preload("res://chapters/chapter_one.gd").CaseStage
const EvidenceEntry = preload("res://investigation/evidence_entry.gd")


func _ready() -> void:
	ChapterOne.progress_changed.connect(_refresh)
	ChapterTwo.progress_changed.connect(_refresh)
	ChapterOne.visit_corridor()
	_refresh()


func _refresh() -> void:
	$ChapterStatus.text = ChapterOne.story_time() + "  ·  " + ChapterOne.objective()
	$Investigation/SealPoint.disabled = not ChapterOne.commission_accepted
	$Investigation/YardExit.disabled = not ChapterOne.commission_accepted
	var at_ending := ChapterOne.case_stage == Case.EPILOGUE
	$Investigation/SealPoint.visible = not at_ending
	$Investigation/EndingPoint.visible = at_ending
	$Scenery/Door102/Window.color = Color(0.24, 0.29, 0.27) if ChapterOne.case_stage >= Case.EPILOGUE else Color(0.58, 0.59, 0.39)
	if ChapterOne.can_enter_supply_door() or InvestigationLog.has_entry(ChapterOne.SEAL.id):
		$ArrivalHint.text = "正门仍锁着。右侧经外廊通往后院。"
	else:
		$ArrivalHint.text = "门内灯亮了一截。『嗒、拖、嗒』。正门仍锁着。"
	if ChapterTwo.active:
		$RoomTitle.text = "第二章 · 走廊"
		$ChapterStatus.text = ChapterTwo.status()
	elif ChapterTwo.can_start():
		$ChapterStatus.text = ChapterOne.story_time() + "  ·  第一章已完成，回前台可开始第二章"


func _on_seal_inspected(_entry: Resource) -> void:
	if ChapterOne.inspect_seal():
		$Investigation.inspect(ChapterOne.SEAL)


func _on_ending_requested() -> void:
	if $InvestigationHud.is_open() or ChapterOne.case_stage != Case.EPILOGUE:
		return
	$Investigation.clear_approach_hint()
	ChapterOne.finish_chapter()
	var ending := EvidenceEntry.new()
	ending.title = "第一章完 · 上锁的教室"
	ending.description = "走廊尽头，102 的灯已经灭了。器材门那边又响了一声，是韩素推着空车过门槛。\n\n正门封条还在。白线缝过的报修册留在 A01，等着移交。"
	ending.preview = ChapterOne.SEAL.preview
	$InvestigationHud.show_evidence(ending, false, "开始第二章", RoomTransition.start_chapter_two)
