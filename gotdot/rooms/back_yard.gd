extends Node2D


func _ready() -> void:
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
	var door_open := ChapterThree.can_enter_supply_door()
	var han_su_point = $Investigation/HanSuPoint
	$RoomTitle.text = "第三章 · 后院雨棚"
	$ChapterStatus.text = ChapterThree.status()
	$Investigation/CartPoint.hide()
	han_su_point.visible = ChapterThree.can_open_supply_door() and not door_open
	han_su_point.evidence = null
	han_su_point.interaction_label = "请韩素打开器材门"
	han_su_point.tooltip_text = han_su_point.interaction_label
	han_su_point.accessibility_name = han_su_point.interaction_label
	han_su_point.approach_hint = "走到推车旁，请韩素打开器材门"
	$WalkableFloor/DepthSort/HanSu.visible = han_su_point.visible
	$Investigation/SupplyDoorExit.travel_allowed = door_open
	$Investigation/SupplyDoorExit.interaction_label = "从器材门进 102" if door_open else "检查器材门"


func _on_han_su_requested() -> void:
	if ChapterThree.can_open_supply_door() and not ChapterThree.can_enter_supply_door():
		$Investigation.inspect(ChapterThree.SUPPLY_ACCESS)


func _on_evidence_inspected(entry: Resource) -> void:
	$Investigation.inspect(entry)
	_refresh()


func _on_supply_door_blocked() -> void:
	if ChapterThree.active:
		if ChapterThree.can_open_supply_door():
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
