extends Node2D

const HanSuActor = preload("res://actors/han_su.gd")

@onready var _investigation = $Investigation
@onready var _hud = $InvestigationHud
@onready var _reasoning = $ReturnReasoning


func _ready() -> void:
	_reasoning.setup(ChapterThree.VISITOR_CHOICES, ChapterThree.RETURN_CHOICES)
	ChapterTwo.progress_changed.connect(_refresh)
	ChapterThree.progress_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	if ChapterThree.active:
		_refresh_saturday()
		return
	if ChapterTwo.active:
		var can_revisit := ChapterTwo.can_revisit_102()
		$RoomTitle.text = "第二章 · 后院"
		$Investigation/HanSuPoint.hide()
		$Investigation/CartPoint.hide()
		$Investigation/SupplyDoorExit.travel_allowed = can_revisit
		$Investigation/SupplyDoorExit.interaction_label = "从器材门进 102" if can_revisit else "检查器材门"
		$ChapterStatus.text = ChapterTwo.status()
		return
	var can_enter := ChapterOne.can_enter_supply_door()
	$Investigation/SupplyDoorExit.travel_allowed = can_enter
	$Investigation/SupplyDoorExit.interaction_label = "从器材门进 102" if can_enter else "检查器材门"
	var objective := ChapterOne.objective() if can_enter else "找推车旁的韩素核对后门授权"
	$ChapterStatus.text = ChapterOne.story_time() + "  ·  " + objective


func _refresh_saturday() -> void:
	if ChapterThree.final_review_started:
		_refresh_final_review()
		return
	var door_open := ChapterThree.can_enter_supply_door()
	var appointment := ChapterThree.appointment_started
	var returning := appointment and ChapterThree.has_departure_record()
	var has_stand := InvestigationLog.has_entry(ChapterThree.RETURNED_STAND.id)
	var han_su_point = $Investigation/HanSuPoint
	$RoomTitle.text = "第三章 · 后院雨棚"
	$ChapterStatus.text = ChapterThree.status()
	$Investigation/CartPoint.hide()
	han_su_point.visible = ChapterThree.can_open_supply_door() and not door_open and not appointment
	han_su_point.evidence = null
	han_su_point.interaction_label = "请韩素打开器材门"
	han_su_point.tooltip_text = han_su_point.interaction_label
	han_su_point.accessibility_name = han_su_point.interaction_label
	han_su_point.approach_hint = "走到推车旁，请韩素打开器材门"
	$WalkableFloor/DepthSort/HanSu.visible = han_su_point.visible or returning
	$Investigation/SupplyDoorExit.travel_allowed = door_open and not appointment
	$Investigation/SupplyDoorExit.interaction_label = "从器材门进 102" if door_open and not appointment else "检查器材门"
	$Scenery/ReturnMailbox.visible = ChapterThree.has_location_finding()
	$Investigation/ReturnMessagePoint.visible = ChapterThree.has_location_finding() and not appointment
	$WalkableFloor/DepthSort/XuNan.visible = returning
	$WalkableFloor/DepthSort/ReturnedStand.visible = returning
	$Investigation/ReturnedStandPoint.visible = returning
	$Investigation/ReturnSignOffPoint.visible = returning and has_stand
	if returning:
		$Scenery/Bench.position = Vector2(597, 321)
		$WalkableFloor/DepthSort/HanSu.position = Vector2(657, 343)
		$WalkableFloor/DepthSort/HanSu.pose = HanSuActor.Pose.FRONT
	var action := "请韩素签收"
	if ChapterThree.is_complete():
		action = "回看第三章结案"
	elif ChapterThree.can_submit_conclusion():
		action = "向韩素提交归还结论"
	$Investigation/ReturnSignOffPoint.interaction_label = action


func _refresh_final_review() -> void:
	$RoomTitle.text = "终章 · 后院雨棚"
	$ChapterStatus.text = ChapterThree.status()
	$Investigation/HanSuPoint.hide()
	$Investigation/CartPoint.hide()
	$Investigation/ReturnMessagePoint.hide()
	$Investigation/ReturnedStandPoint.hide()
	$Investigation/ReturnSignOffPoint.hide()
	$WalkableFloor/DepthSort/HanSu.hide()
	$WalkableFloor/DepthSort/XuNan.hide()
	$WalkableFloor/DepthSort/ReturnedStand.hide()
	$Scenery/ReturnMailbox.visible = ChapterThree.has_location_finding()
	$Scenery/Bench.position = Vector2(597, 321)
	$Investigation/SupplyDoorExit.travel_allowed = true
	$Investigation/SupplyDoorExit.interaction_label = "从器材门回 102"


func _on_han_su_requested() -> void:
	if ChapterThree.can_open_supply_door() and not ChapterThree.can_enter_supply_door():
		$Investigation.inspect(ChapterThree.SUPPLY_ACCESS)


func _on_returned_stand_requested() -> void:
	if _hud.is_open() or not ChapterThree.has_departure_record():
		return
	if not InvestigationLog.has_entry(ChapterThree.RETURNED_STAND.id):
		$WoodScrape.play()
	_investigation.inspect(ChapterThree.RETURNED_STAND)


func _on_return_sign_off_requested() -> void:
	if ChapterThree.is_complete():
		if ChapterThree.final_review_started:
			_investigation.inspect(ChapterThree.CONCLUSION)
		else:
			_hud.show_evidence(
				ChapterThree.CONCLUSION, false, "进入终章复核", RoomTransition.start_final_review
			)
	elif ChapterThree.can_submit_conclusion():
		_investigation.clear_approach_hint()
		_hud.show_presentation(_reasoning, "核对两晚的来访", true)
	elif InvestigationLog.has_entry(ChapterThree.RETURNED_STAND.id):
		_investigation.inspect(ChapterThree.RECEIPT)


func _on_return_conclusion_submitted(visitor: int, item: int) -> void:
	var feedback := ChapterThree.submit_conclusion(visitor, item)
	if feedback.is_empty():
		_hud.show_evidence(
			ChapterThree.CONCLUSION, false, "进入终章复核", RoomTransition.start_final_review
		)
	else:
		_reasoning.show_feedback("韩素：" + feedback)


func _on_evidence_inspected(entry: Resource) -> void:
	$Investigation.inspect(entry)
	_refresh()


func _on_supply_door_blocked() -> void:
	if ChapterThree.active:
		if ChapterThree.is_complete():
			$Investigation.show_approach_hint($Investigation/SupplyDoorStand.global_position, "等何青回来，一起进 102 复核")
		elif ChapterThree.appointment_started:
			$Investigation.show_approach_hint($Investigation/ReturnedStandStand.global_position, "先到雨棚的长凳旁办完归还")
		elif ChapterThree.can_open_supply_door():
			$Investigation.show_approach_hint($Investigation/HanSuStand.global_position, "请韩素打开器材门")
		else:
			$Investigation.show_approach_hint($Investigation/PassageStand.global_position, "先回走廊，从 102 正门高窗观察")
		return
	if ChapterTwo.active:
		var hint := "韩素已锁上器材门" if ChapterTwo.is_complete() else "先回前台核对原图和收页便签"
		$Investigation.show_approach_hint(
			$Investigation/PassageStand.global_position, hint
		)
		return
	$Investigation.show_approach_hint(
		$Investigation/HanSuStand.global_position, "先去推车旁找韩素"
	)
