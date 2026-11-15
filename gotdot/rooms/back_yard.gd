extends Node2D


func _ready() -> void:
	ChapterTwo.progress_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
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


func _on_evidence_inspected(entry: Resource) -> void:
	$Investigation.inspect(entry)
	_refresh()


func _on_supply_door_blocked() -> void:
	if ChapterTwo.active:
		$Investigation.show_approach_hint(
			$Investigation/PassageStand.global_position, "先回前台核对原图和收页便签"
		)
		return
	$Investigation.show_approach_hint(
		$Investigation/HanSuStand.global_position, "先去推车旁找韩素"
	)
