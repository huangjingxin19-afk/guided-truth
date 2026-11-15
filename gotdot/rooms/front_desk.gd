extends Node2D

const Case = preload("res://chapters/chapter_one.gd").CaseStage
const EvidenceEntry = preload("res://investigation/evidence_entry.gd")

@onready var _investigation = $Investigation
@onready var _hud = $InvestigationHud
@onready var _reasoning = $Reasoning


func _ready() -> void:
	_reasoning.setup(ChapterTwo.ORDER_CHOICES, ChapterTwo.LOCATION_CHOICES)
	ChapterOne.progress_changed.connect(_refresh)
	ChapterTwo.progress_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	$ChapterStatus.text = ChapterOne.story_time() + "  ·  " + ChapterOne.objective()
	$Investigation/HeQingPoint.interaction_label = "重看委托" if ChapterOne.commission_accepted else "领取委托"
	$Investigation/CorridorExit.disabled = not ChapterOne.commission_accepted
	var stage := ChapterOne.case_stage
	var he_qing_in_102 := ChapterOne.is_he_qing_in_102()
	$Scenery/HeQing.visible = not he_qing_in_102
	$Investigation/HeQingPoint.visible = not he_qing_in_102
	$Scenery/ZhouWen.visible = stage != Case.SIGN_OFF
	$WalkableFloor/DepthSort/Counter/FridayPapers.visible = ChapterTwo.active
	$Investigation/PhotoPoint.visible = ChapterTwo.active
	$Investigation/ReceiptPoint.visible = ChapterTwo.active
	$Investigation/FilePocketPoint.visible = ChapterTwo.active
	if ChapterTwo.active:
		$RoomTitle.text = "第二章 · 原页复原"
		$ChapterStatus.text = ChapterTwo.status()
		$WalkableFloor/DepthSort/Counter/WorkOrder.hide()
		$WalkableFloor/DepthSort/Counter/Note.hide()
		$Scenery/ZhouWen.hide()
		$Investigation/HeQingPoint.interaction_label = "核对原页委托"
		if ChapterTwo.can_submit_reasoning():
			$Investigation/HeQingPoint.interaction_label = "提交原页判断"
		elif ChapterTwo.has_finding():
			$Investigation/HeQingPoint.interaction_label = "回看原页判断"
	elif ChapterTwo.can_start():
		$Investigation/HeQingPoint.interaction_label = "开始第二章"


func _on_he_qing_interacted() -> void:
	if ChapterTwo.active:
		_show_chapter_two_commission_or_reasoning()
		return
	if ChapterTwo.can_start():
		RoomTransition.start_chapter_two()
		return
	var first_time := not ChapterOne.commission_accepted
	ChapterOne.accept_commission()
	_investigation.clear_approach_hint()
	_hud.show_evidence(ChapterOne.COMMISSION, false, "展开周闻的便笺" if first_time else "查看器材便笺", _show_note)


func _show_note() -> void:
	_hud.show_evidence(ChapterOne.EQUIPMENT_NOTE)


func _on_photo_inspected(entry: EvidenceEntry) -> void:
	_investigation.inspect(entry, "对照转发截图", _show_forwarded_crop)


func _show_forwarded_crop() -> void:
	InvestigationLog.record(ChapterTwo.FORWARDED_CROP)
	_hud.show_evidence(ChapterTwo.FORWARDED_CROP, false, "返回群聊原图", _show_original_photo)


func _show_original_photo() -> void:
	_hud.show_evidence(ChapterTwo.PHOTO, false, "对照转发截图", _show_forwarded_crop)


func _show_chapter_two_commission_or_reasoning() -> void:
	_investigation.clear_approach_hint()
	if ChapterTwo.has_finding():
		_hud.show_evidence(ChapterTwo.FINDING)
	elif ChapterTwo.can_submit_reasoning():
		_hud.show_presentation(_reasoning, "核对周四原页", true)
	else:
		var commission := EvidenceEntry.new()
		commission.title = "少掉的一页"
		commission.description = (
			"邵宁：「群里说可能有人特意拿走了周四那页。能不能先看照片是哪张？大家都在转截过的那一块。」\n\n"
			+ "何青：「先查柜台的原图、收页便签和登记夹。看过原图和便签后，可以请韩素从器材门开门，沿周四的路线核对 A01。」"
		)
		_hud.show_evidence(commission)


func _on_reasoning_submitted(order: int, location: int) -> void:
	var feedback := ChapterTwo.submit_reasoning(order, location)
	if feedback.is_empty():
		_hud.show_evidence(ChapterTwo.FINDING)
	else:
		_reasoning.show_feedback("何青：" + feedback)
