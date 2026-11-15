extends Node2D

const Case = preload("res://chapters/chapter_one.gd").CaseStage
const EvidenceEntry = preload("res://investigation/evidence_entry.gd")

@onready var _investigation = $Investigation
@onready var _hud = $InvestigationHud
@onready var _reasoning = $Reasoning
@onready var _loan_cards = $LoanCards


func _ready() -> void:
	if ChapterTwo.active:
		$Scenery/ZhouWen.position = $Scenery/RecycleBasket.position + Vector2(28, -16)
	_reasoning.setup(ChapterTwo.ORDER_CHOICES, ChapterTwo.PAGE_CHOICES)
	_loan_cards.setup(ChapterThree.LOAN_CHOICES)
	ChapterOne.progress_changed.connect(_refresh)
	ChapterTwo.progress_changed.connect(_refresh)
	ChapterThree.progress_changed.connect(_refresh)
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
	$Scenery/ShaoNing.visible = ChapterTwo.active
	$Investigation/ShaoNingPoint.visible = ChapterTwo.active
	$Scenery/HandoverBoard.visible = ChapterTwo.has_withdrawn_photo()
	$Investigation/HandoverBoardPoint.visible = ChapterTwo.has_withdrawn_photo()
	var show_pickup := ChapterTwo.can_document_accident() and not ChapterTwo.is_complete()
	var pickup_seen := InvestigationLog.has_entry(ChapterTwo.SPRING_LEDGER.id)
	$Scenery/RecycleBasket.visible = show_pickup
	$Scenery/RecycleBasket/SpringLedger.visible = not pickup_seen
	$Investigation/SpringLedgerPoint.visible = show_pickup and not pickup_seen
	if ChapterThree.active:
		_refresh_saturday()
	elif ChapterTwo.active:
		$RoomTitle.text = "第二章 · 少掉的一页"
		$ChapterStatus.text = ChapterTwo.status()
		$WalkableFloor/DepthSort/Counter/WorkOrder.hide()
		$WalkableFloor/DepthSort/Counter/Note.hide()
		$Scenery/ZhouWen.visible = show_pickup and not pickup_seen
		if ChapterTwo.has_withdrawn_photo():
			var phone = $Investigation/PhotoPoint
			phone.evidence = ChapterTwo.PHOTO_EXCERPT
			phone.tooltip_text = ChapterTwo.PHOTO_EXCERPT.title
			phone.accessibility_name = ChapterTwo.PHOTO_EXCERPT.title
			phone.approach_hint = "靠近柜台左侧的手机，查看照片局部留档"
		$Investigation/ShaoNingPoint.interaction_label = _shao_ning_action()
		$Investigation/HeQingPoint.interaction_label = "核对原页委托"
		if ChapterTwo.can_submit_reasoning():
			$Investigation/HeQingPoint.interaction_label = "提交原页判断"
		elif ChapterTwo.has_finding():
			$Investigation/HeQingPoint.interaction_label = "回看原页判断"
	elif ChapterTwo.can_start():
		$Investigation/HeQingPoint.interaction_label = "开始第二章"


func _refresh_saturday() -> void:
	var before_appointment := not ChapterThree.appointment_started
	var loan_confirmed := InvestigationLog.has_entry(ChapterThree.LOAN_CARD.id)
	var notice_read := InvestigationLog.has_entry(ChapterThree.RETURN_NOTICE.id)
	var call_made := InvestigationLog.has_entry(ChapterThree.CALL.id)
	var papers = $WalkableFloor/DepthSort/Counter
	$RoomTitle.text = "第三章 · 前台"
	$ChapterStatus.text = ChapterThree.status()
	papers.get_node("WorkOrder").hide()
	papers.get_node("Note").hide()
	papers.get_node("FridayPapers").hide()
	$Investigation/PhotoPoint.hide()
	$Investigation/ReceiptPoint.hide()
	$Investigation/FilePocketPoint.hide()
	$Investigation/HeQingPoint.hide()
	$Investigation/ShaoNingPoint.hide()
	$Investigation/HandoverBoardPoint.hide()
	$Scenery/ZhouWen.visible = before_appointment and loan_confirmed
	$Scenery/ZhouWen.position = Vector2(621, 317)
	papers.get_node("SaturdayCards").visible = before_appointment and (ChapterThree.can_check_loan_cards() or loan_confirmed)
	papers.get_node("SaturdayNotice").visible = before_appointment and loan_confirmed
	$Scenery/SaturdayHanSu.visible = before_appointment and notice_read
	$Scenery/HandoverBoard/ReturnNoticeCorner.visible = before_appointment and loan_confirmed
	$Investigation/LoanCardsPoint.visible = papers.get_node("SaturdayCards").visible
	$Investigation/LoanCardsPoint.interaction_label = "回看借用卡" if loan_confirmed else "核对三张借用卡"
	$Investigation/ReturnNoticePoint.visible = papers.get_node("SaturdayNotice").visible
	$Investigation/ReturnCallPoint.visible = $Scenery/SaturdayHanSu.visible
	$Investigation/ReturnCallPoint.interaction_label = "回看归还通话" if call_made else "给韩素看交回通知"
	$Scenery/HandoverBoard/AppointmentSlip.visible = InvestigationLog.has_entry(ChapterThree.DUTY_BOARD.id)
	$Investigation/DutyBoardPoint.visible = before_appointment and call_made
	$Investigation/DutyBoardPoint.interaction_label = "查看赴约安排" if ChapterThree.can_confirm_appointment() else "登记赴约安排"


func _on_loan_cards_requested() -> void:
	if ChapterThree.can_check_loan_cards():
		_investigation.clear_approach_hint()
		_hud.show_presentation(_loan_cards, "核对借用卡", true)
	elif InvestigationLog.has_entry(ChapterThree.LOAN_CARD.id):
		_investigation.inspect(ChapterThree.LOAN_CARD)


func _on_loan_card_submitted(answer: int, _unused: int) -> void:
	var feedback := ChapterThree.submit_loan_card(answer)
	if feedback.is_empty():
		_hud.show_evidence(ChapterThree.LOAN_CARD)
	else:
		_loan_cards.show_feedback(feedback)


func _on_return_call_requested() -> void:
	if InvestigationLog.has_entry(ChapterThree.RETURN_NOTICE.id):
		_investigation.inspect(ChapterThree.CALL)


func _on_duty_board_requested() -> void:
	if not InvestigationLog.has_entry(ChapterThree.CALL.id) or _hud.is_open():
		return
	_investigation.clear_approach_hint()
	InvestigationLog.record(ChapterThree.DUTY_BOARD)
	if ChapterThree.can_confirm_appointment():
		_hud.show_evidence(
			ChapterThree.DUTY_BOARD, false, "确认赴约", RoomTransition.start_saturday_appointment
		)


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
	if ChapterTwo.has_withdrawn_photo():
		_investigation.inspect(ChapterTwo.PHOTO_EXCERPT)
	else:
		_investigation.inspect(entry, "对照转发截图", _show_forwarded_crop)


func _show_forwarded_crop() -> void:
	if ChapterTwo.has_withdrawn_photo():
		return
	InvestigationLog.record(ChapterTwo.FORWARDED_CROP)
	_hud.show_evidence(ChapterTwo.FORWARDED_CROP, false, "返回群聊原图", _show_original_photo)


func _show_original_photo() -> void:
	if not ChapterTwo.has_withdrawn_photo():
		_hud.show_evidence(ChapterTwo.PHOTO, false, "对照转发截图", _show_forwarded_crop)


func _shao_ning_action() -> String:
	if ChapterTwo.has_withdrawn_photo():
		return "向邵宁问登记摘录"
	if ChapterTwo.has_finding():
		return "向邵宁确认收页"
	if InvestigationLog.has_entry(ChapterTwo.PHOTO.id):
		return "请邵宁联系发图人"
	return "问邵宁群聊传闻"


func _on_shao_ning_interacted() -> void:
	_investigation.clear_approach_hint()
	if ChapterTwo.has_withdrawn_photo():
		_hud.show_evidence(ChapterTwo.PHOTO_EXCERPT)
	elif ChapterTwo.has_finding():
		var confirmation := EvidenceEntry.new()
		confirmation.title = "邵宁确认收页"
		confirmation.description = (
			"邵宁：「我看到号码就把纸收了。后来群里说有人翻桌子，我就更不敢先开口。」\n\n"
			+ "何青：「照片先撤。以后有人问来过什么人，我给他看摘录。」"
		)
		_hud.show_evidence(confirmation, false, "保存局部并撤图", _save_photo_excerpt)
	elif InvestigationLog.has_entry(ChapterTwo.PHOTO.id):
		_investigation.inspect(ChapterTwo.PHOTO_CALL)
	else:
		var message := EvidenceEntry.new()
		message.title = "邵宁的群聊消息"
		message.description = "邵宁：「大家都在转截过的那一块。我问过发图的人，『群里这张有原图吗？请先别再转。』你可以先看柜台上最早那条。」"
		_hud.show_evidence(message)


func _save_photo_excerpt() -> void:
	if ChapterTwo.archive_and_withdraw_photo():
		_hud.show_evidence(ChapterTwo.PHOTO_EXCERPT)


func _on_handover_board_inspected(entry: EvidenceEntry) -> void:
	if ChapterTwo.has_withdrawn_photo():
		_investigation.inspect(entry)


func _on_spring_ledger_requested() -> void:
	if ChapterTwo.can_document_accident() and not ChapterTwo.is_complete():
		_investigation.inspect(ChapterTwo.SPRING_LEDGER)


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


func _on_reasoning_submitted(order: int, candidate: int) -> void:
	var feedback := ChapterTwo.submit_reasoning(order, candidate)
	if feedback.is_empty():
		_hud.show_evidence(ChapterTwo.FINDING)
	else:
		_reasoning.show_feedback("何青：" + feedback)
