extends Node2D

const Case = preload("res://chapters/chapter_one.gd").CaseStage
const EvidenceEntry = preload("res://investigation/evidence_entry.gd")

@onready var _location_reasoning = $LocationReasoning


func _ready() -> void:
	_location_reasoning.setup(ChapterThree.LOCATION_CHOICES)
	ChapterOne.progress_changed.connect(_refresh)
	ChapterTwo.progress_changed.connect(_refresh)
	ChapterThree.progress_changed.connect(_refresh)
	ChapterOne.visit_corridor()
	_refresh()


func _refresh() -> void:
	$ChapterStatus.text = ChapterOne.story_time() + "  ·  " + ChapterOne.objective()
	$Investigation/SealPoint.disabled = not ChapterOne.commission_accepted
	$Investigation/YardExit.disabled = not ChapterOne.commission_accepted
	var at_ending := ChapterOne.case_stage == Case.EPILOGUE
	$Investigation/SealPoint.visible = not at_ending
	$Investigation/EndingPoint.visible = at_ending
	$Scenery/WestStairBoard.visible = ChapterTwo.active
	$Investigation/AccidentPoint.visible = ChapterTwo.can_document_accident()
	$Investigation/NightPatrolPoint.visible = ChapterTwo.can_watch_night_patrol()
	$Scenery/NightShade.visible = ChapterTwo.is_complete()
	$Scenery/Door102/Window.color = Color(0.24, 0.29, 0.27) if ChapterOne.case_stage >= Case.EPILOGUE else Color(0.58, 0.59, 0.39)
	$WalkableFloor/DepthSort/SaturdayHanSu.visible = ChapterThree.active
	$Investigation/SaturdaySealPoint.visible = ChapterThree.active
	$Investigation/SaturdayHanSuPoint.visible = ChapterThree.active
	$Investigation/HighWindowPoint.visible = ChapterThree.can_observe_high_window()
	if ChapterThree.active:
		_refresh_saturday()
		return
	if ChapterOne.can_enter_supply_door() or InvestigationLog.has_entry(ChapterOne.SEAL.id):
		$ArrivalHint.text = "正门仍锁着。右侧经外廊通往后院。"
	else:
		$ArrivalHint.text = "门内灯亮了一截。『嗒、拖、嗒』。正门仍锁着。"
	if ChapterTwo.active:
		$RoomTitle.text = "第二章 · 走廊"
		$ChapterStatus.text = ChapterTwo.status()
		if ChapterTwo.can_watch_night_patrol():
			$Investigation/SealPoint.hide()
			$Investigation/NightPatrolPoint.interaction_label = (
				"回看夜巡消息" if ChapterTwo.is_complete() else "查看韩素夜巡"
			)
			$ArrivalHint.text = "值班灯已经切到夜间模式。"
		if InvestigationLog.has_entry(ChapterTwo.ACCIDENT_NOTICE.id):
			$Investigation/AccidentPoint.interaction_label = "回看旧事故说明"
	elif ChapterTwo.can_start():
		$ChapterStatus.text = ChapterOne.story_time() + "  ·  第一章已完成，回前台可开始第二章"


func _refresh_saturday() -> void:
	$RoomTitle.text = "第三章 · 走廊"
	$ChapterStatus.text = ChapterThree.status()
	$Scenery/NightShade.hide()
	$Scenery/Door102/Window.color = Color(0.44, 0.54, 0.51)
	$Investigation/SealPoint.hide()
	$Investigation/NightPatrolPoint.hide()
	$Investigation/AccidentPoint.interaction_label = "回看旧事故说明"
	$ArrivalHint.text = "正门仍锁着。右侧经外廊通往后院。"
	var han_su_point = $Investigation/SaturdayHanSuPoint
	if ChapterThree.has_location_finding():
		han_su_point.interaction_label = "回看人影位置"
	elif ChapterThree.can_submit_location():
		han_su_point.interaction_label = "向韩素说明人影位置"
	elif ChapterThree.can_observe_high_window():
		han_su_point.interaction_label = "回看韩素的委托"


func _on_saturday_han_su_requested() -> void:
	var hud = $InvestigationHud
	if hud.is_open():
		return
	if ChapterThree.has_location_finding():
		$Investigation.inspect(ChapterThree.LOCATION_FINDING)
	elif ChapterThree.can_submit_location():
		$Investigation.clear_approach_hint()
		hud.show_presentation(_location_reasoning, "判断人影的位置", true)
	else:
		$Investigation.inspect(ChapterThree.COMMISSION)


func _on_location_submitted(location: int, _unused: int) -> void:
	var feedback := ChapterThree.submit_location(location)
	if feedback.is_empty():
		$InvestigationHud.show_evidence(ChapterThree.LOCATION_FINDING)
	else:
		_location_reasoning.show_feedback("韩素：" + feedback)


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


func _on_accident_requested() -> void:
	if ChapterTwo.can_document_accident():
		$Investigation.inspect(ChapterTwo.ACCIDENT_NOTICE)


func _on_night_patrol_requested() -> void:
	if $InvestigationHud.is_open() or not ChapterTwo.can_watch_night_patrol():
		return
	$Investigation.clear_approach_hint()
	if ChapterTwo.is_complete():
		$InvestigationHud.show_evidence(ChapterTwo.NIGHT_MESSAGE, false, "回看结尾", _show_friday_ending)
		return
	var patrol := EvidenceEntry.new()
	patrol.title = "周五 21:10 · 韩素巡楼"
	patrol.description = "声控灯刚灭，器材架旁露出半个人影。韩素贴住窄窗挡掉反光，看见那人提着细长的袋子，抬了两次手。门铃响了两声。"
	patrol.preview = ChapterTwo.NIGHT_MESSAGE.preview
	patrol.preview_scale = ChapterTwo.NIGHT_MESSAGE.preview_scale
	$InvestigationHud.show_evidence(patrol, false, "查看韩素发来的消息", _finish_night_patrol)


func _finish_night_patrol() -> void:
	ChapterTwo.finish_night_patrol()
	$InvestigationHud.show_evidence(ChapterTwo.NIGHT_MESSAGE, false, "结束第二章", _show_friday_ending)


func _show_friday_ending() -> void:
	var ending := EvidenceEntry.new()
	ending.title = "第二章完 · 少掉的一页"
	ending.description = "周四的访客页收回了内袋，西梯的旧说明留在林禾的笔记里。\n\n两扇门都锁着，韩素看见的人站在哪里？\n\n第三章《雨棚下的人》"
	$InvestigationHud.show_evidence(ending, false, "开始第三章", RoomTransition.start_chapter_three)
