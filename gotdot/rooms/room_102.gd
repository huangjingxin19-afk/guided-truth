extends Node2D

const EvidenceEntry = preload("res://investigation/evidence_entry.gd")
const HanSuActor = preload("res://actors/han_su.gd")
const InvestigationHud = preload("res://ui/investigation_hud.gd")
const RoomInvestigation = preload("res://investigation/room_investigation.gd")
const ThresholdReenactment = preload("res://rooms/room_102_threshold_reenactment.gd")
const Reasoning = preload("res://ui/reasoning_form.gd")
const WalkableFloor = preload("res://rooms/walkable_floor.gd")
const Stage = preload("res://chapters/chapter_one.gd").ReenactmentStage
const Case = preload("res://chapters/chapter_one.gd").CaseStage
const LEDGER = preload("res://props/repair_ledger.tscn")
const SPRING_LEDGER = preload("res://props/spring_repair_ledger.tscn")
const FINAL_REVIEW = preload("res://investigation/final_review_discrepancy.tres")
const DESK_SHIFT := Vector2(0, 28)

@onready var _investigation: RoomInvestigation = $Investigation
@onready var _hud: InvestigationHud = $InvestigationHud
@onready var _reenactment: ThresholdReenactment = $ThresholdReenactment
@onready var _foot_pad: Node2D = $Scenery/FootPad
@onready var _foot_pad_point: Button = $Investigation/FootPadPoint
@onready var _han_su_point: Button = $Investigation/HanSuPoint
@onready var _foot_pad_stand: Marker2D = $Investigation/FootPadStand
@onready var _reasoning: Reasoning = $Reasoning
@onready var _floor: WalkableFloor = $WalkableFloor
@onready var _desk: StaticBody2D = $WalkableFloor/DepthSort/LongDesk
@onready var _desk_start := _desk.position


func _ready() -> void:
	_reasoning.setup(ChapterOne.ROUTE_CHOICES, ChapterOne.SOUND_CHOICES)
	ChapterOne.progress_changed.connect(_refresh)
	ChapterTwo.progress_changed.connect(_refresh)
	ChapterThree.progress_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	if not is_inside_tree():
		return
	var stage := ChapterOne.reenactment_stage
	var pad_on_floor := stage == Stage.FIRST_PASS or stage == Stage.INSTALL_PAD
	_foot_pad.visible = pad_on_floor
	_foot_pad_point.visible = pad_on_floor
	_han_su_point.visible = stage == Stage.FIRST_PASS or stage == Stage.SECOND_PASS
	_han_su_point.text = "再推一次" if stage == Stage.SECOND_PASS else "看推车过门槛"
	$ChapterStatus.visible = ChapterOne.commission_accepted
	var objective := "在器材门旁找韩素，看第一次过槛" if stage == Stage.FIRST_PASS else ChapterOne.objective()
	$ChapterStatus.text = ChapterOne.story_time() + "  ·  " + objective
	$Investigation/YardExit.visible = ChapterOne.can_enter_supply_door()
	_refresh_case()
	$Scenery/ShelterGlass.visible = ChapterThree.active
	$Investigation/DeskViewPoint.visible = ChapterThree.can_enter_supply_door()
	if ChapterThree.active:
		_refresh_saturday()
	elif ChapterTwo.active:
		$ChapterStatus.text = ChapterTwo.status()
		$Investigation/WheelTracksPoint.evidence = ChapterTwo.TRACKS
		$Investigation/WheelTracksPoint.tooltip_text = ChapterTwo.TRACKS.title
		$Investigation/WheelTracksPoint.accessibility_name = ChapterTwo.TRACKS.title
		$Investigation/ArchivePoint.interaction_label = "核对桌后 A01"


func _refresh_saturday() -> void:
	if ChapterThree.final_review_started:
		_refresh_final_review()
		return
	var appointment := ChapterThree.appointment_started
	var can_leave := not appointment or ChapterThree.has_departure_record()
	$ChapterStatus.text = ChapterThree.status()
	$Investigation/WheelTracksPoint.hide()
	$Investigation/ArchivePoint.hide()
	$Investigation/DeskViewPoint.visible = ChapterThree.can_enter_supply_door() and not appointment
	$Investigation/DeparturePoint.visible = appointment
	$Scenery/OpenG03.visible = appointment
	$Scenery/ZhouWen.visible = appointment
	$Scenery/HanSu.visible = appointment
	if appointment:
		$Scenery/ZhouWen.position = Vector2(354, 287)
		$Scenery/HanSu.position = Vector2(419, 290)
		$Scenery/HanSu.pose = HanSuActor.Pose.BACK
	$Investigation/YardExit.travel_allowed = can_leave
	$Investigation/YardExit.interaction_label = "随韩素去雨棚" if appointment and can_leave else "返回后院"


func _refresh_final_review() -> void:
	$RoomNumber.text = "102"
	$ChapterStatus.text = ChapterThree.status()
	$Investigation/WheelTracksPoint.hide()
	$Investigation/FootPadPoint.hide()
	$Investigation/HanSuPoint.hide()
	$Investigation/ReasoningPoint.hide()
	$Investigation/DrawerPoint.hide()
	$Investigation/SignOffPoint.hide()
	$Investigation/DeskViewPoint.hide()
	$Investigation/DeparturePoint.hide()
	$Investigation/YardExit.visible = ChapterThree.handover_paused
	$Investigation/YardExit.travel_allowed = ChapterThree.handover_paused
	$Investigation/YardExit.interaction_label = "返回后院"
	$Investigation/ArchivePoint.show()
	$Investigation/ArchivePoint.interaction_label = "复核 A01 箱口的报修册"
	$Investigation/ArchivePoint.approach_hint = "走到正门内侧的 A01 资料箱旁"
	$Scenery/ArchiveBox.show()
	$Scenery/FinalDeskScrape.show()
	$Scenery/ArchiveBox.position = Vector2(310, 418)
	$Investigation/ArchivePoint.offset_left = 278.0
	$Investigation/ArchivePoint.offset_top = 395.0
	$Investigation/ArchivePoint.offset_right = 342.0
	$Investigation/ArchivePoint.offset_bottom = 439.0
	$Investigation/ArchiveStand.position = Vector2(310, 449)
	$Scenery/ArchiveBox/Ledger/WhiteStitches.hide()
	$Scenery/ArchiveBox/CupRing.show()
	$Investigation/G03Point.visible = ChapterThree.handover_paused
	$Investigation/FinalHeQingPoint.visible = ChapterThree.handover_paused
	$Investigation/FinalHanSuPoint.visible = ChapterThree.handover_paused
	$Scenery/HeQing.show()
	$Scenery/HeQing.position = Vector2(795, 306)
	$Scenery/HanSu.show()
	$Scenery/HanSu.position = Vector2(750, 307)
	$Scenery/HanSu.pose = HanSuActor.Pose.LEFT
	$Scenery/ClosedG03.visible = not _has_final_entry(ChapterThree.G03_OPEN)
	$Scenery/OpenG03.visible = ChapterThree.handover_paused and _has_final_entry(ChapterThree.AUTUMN_LEDGER)
	$Scenery/FinalOpenG03.visible = ChapterThree.handover_paused and _has_final_entry(ChapterThree.G03_OPEN) and not _has_final_entry(ChapterThree.AUTUMN_LEDGER)
	$Scenery/OpenG03.position = Vector2(697, 248)
	$Scenery/FinalOpenG03.position = Vector2(697, 248)
	$Investigation/G03Point.interaction_label = "检查 G03"
	$Investigation/FinalHeQingPoint.interaction_label = "请打开 G03"
	$Investigation/FinalHanSuPoint.interaction_label = "向韩素核对离场情况"
	$Scenery/ZhouWen.show()
	$Scenery/ZhouWen.position = Vector2(414, 274)
	var final_desk_position := _desk_start + Vector2(0, -28)
	if _desk.position != final_desk_position:
		_desk.position = final_desk_position
		_floor.refresh_navigation()


func _has_final_entry(entry: EvidenceEntry) -> bool:
	return InvestigationLog.has_entry(entry.id)


func _on_g03_requested() -> void:
	if _hud.is_open() or not ChapterThree.handover_paused:
		return
	_investigation.clear_approach_hint()
	if _has_final_entry(ChapterThree.AUTUMN_LEDGER):
		_hud.show_evidence(ChapterThree.AUTUMN_LEDGER)
	elif _has_final_entry(ChapterThree.G03_OPEN):
		_hud.show_evidence(
			ChapterThree.G03_OPEN, false, "移开谱架，取出秋册", _take_autumn_ledger
		)
	elif _has_final_entry(ChapterThree.G03_PERMISSION):
		_hud.show_evidence(ChapterThree.G03_PHOTO, false, "打开 G03", _open_g03)
	elif _has_final_entry(ChapterThree.G03_PHOTO):
		_hud.show_evidence(ChapterThree.G03_PHOTO)
	elif _has_final_entry(ChapterThree.G03_TRACE):
		_hud.show_evidence(
			ChapterThree.G03_TRACE, false, "拍下箱缝和装载卡", _photograph_g03
		)
	else:
		ChapterThree.record_final_evidence(ChapterThree.G03_CARD)
		_hud.show_evidence(
			ChapterThree.G03_CARD, false, "检查箱缝", _inspect_g03_trace
		)


func _inspect_g03_trace() -> void:
	ChapterThree.record_final_evidence(ChapterThree.G03_TRACE)
	_hud.show_evidence(
		ChapterThree.G03_TRACE, false, "拍下箱缝和装载卡", _photograph_g03
	)


func _photograph_g03() -> void:
	ChapterThree.record_final_evidence(ChapterThree.G03_PHOTO)
	_hud.show_evidence(ChapterThree.G03_PHOTO)


func _on_final_he_qing_requested() -> void:
	if _hud.is_open() or not ChapterThree.handover_paused:
		return
	_investigation.clear_approach_hint()
	if _has_final_entry(ChapterThree.G03_PHOTO):
		ChapterThree.record_final_evidence(ChapterThree.G03_PERMISSION)
		_hud.show_evidence(ChapterThree.G03_PERMISSION)
	else:
		var response := EvidenceEntry.new()
		response.title = "何青"
		response.description = "先拍下箱缝和装载卡。照片留好，我在场，你再开箱。"
		_hud.show_evidence(response)


func _open_g03() -> void:
	ChapterThree.record_final_evidence(ChapterThree.G03_OPEN)
	_hud.show_evidence(
		ChapterThree.G03_OPEN, false, "移开谱架，取出秋册", _take_autumn_ledger
	)


func _take_autumn_ledger() -> void:
	ChapterThree.record_final_evidence(ChapterThree.AUTUMN_LEDGER)
	_hud.show_evidence(ChapterThree.AUTUMN_LEDGER)


func _on_final_han_su_requested() -> void:
	if _hud.is_open() or not ChapterThree.handover_paused:
		return
	_investigation.clear_approach_hint()
	ChapterThree.record_final_evidence(ChapterThree.HAN_SU_TESTIMONY)
	_hud.show_evidence(ChapterThree.HAN_SU_TESTIMONY)


func _on_yard_exit_blocked() -> void:
	_investigation.show_approach_hint($Investigation/ArchiveStand.global_position, "离开前，先到长桌后面记下 A01、桌脚和 G03")


func _refresh_case() -> void:
	var stage := ChapterOne.case_stage
	$Scenery/HeQing.visible = ChapterOne.is_he_qing_in_102()
	$Investigation/ReasoningPoint.visible = ChapterOne.can_submit_reasoning()
	$Investigation/DrawerPoint.visible = stage == Case.DRAWER or stage == Case.PACK_ARCHIVE
	$Scenery/DrawerUnit/ExposedDrawer.visible = stage >= Case.PACK_ARCHIVE
	$Scenery/DrawerUnit/ExposedDrawer/RepairLedger.visible = stage == Case.PACK_ARCHIVE
	$Scenery/OldDeskFootprints.visible = stage >= Case.PACK_ARCHIVE
	$Scenery/ArchiveBox.visible = stage >= Case.PHOTOGRAPH
	$Investigation/ArchivePoint.interaction_label = "查看 A01" if stage == Case.PHOTOGRAPH else "回看 A01 清点照片"
	$Scenery/ZhouWen.visible = stage == Case.SIGN_OFF
	$Investigation/SignOffPoint.visible = stage == Case.SIGN_OFF

	var desk_position := _desk_start
	if stage >= Case.PACK_ARCHIVE:
		desk_position = _desk_start + Vector2(0, -28) if ChapterThree.final_review_started else _desk_start + DESK_SHIFT
	if _desk.position != desk_position:
		_desk.position = desk_position
		_floor.refresh_navigation()


func _on_reasoning_requested() -> void:
	if ChapterOne.can_submit_reasoning() and not _hud.is_open():
		_investigation.clear_approach_hint()
		_hud.show_presentation(_reasoning, "提交推理", true)


func _on_reasoning_submitted(route: int, sound: int) -> void:
	var feedback := ChapterOne.submit_reasoning(route, sound)
	if feedback.is_empty():
		_hud.show_evidence(ChapterOne.CONCLUSION)
	else:
		_reasoning.show_feedback("何青：" + feedback)


func _on_drawer_requested() -> void:
	if _hud.is_open():
		return
	_investigation.clear_approach_hint()
	var drawer := EvidenceEntry.new()
	drawer.title = "102 下层抽屉"
	drawer.description = "韩素把长桌向前挪开，露出旧桌脚印。最下格放着蓝布报修册和散页。\n韩素：那三针用的是窗帘剩下的白线。"
	drawer.preview = LEDGER
	drawer.preview_scale = 6.0
	_hud.show_evidence(drawer, false, "装入 A01", _pack_archive)
	ChapterOne.open_drawer()


func _pack_archive() -> void:
	ChapterOne.pack_archive()
	var packed := EvidenceEntry.new()
	packed.title = "已装入 A01"
	packed.description = "何青托住纸堆底部，把蓝布报修册和散页原样放入 A01。到箱边拍下白线和箱卡。"
	_hud.show_evidence(packed)


func _on_archive_requested() -> void:
	if _hud.is_open():
		return
	if ChapterThree.final_review_started:
		if ChapterThree.handover_paused:
			_hud.show_evidence(FINAL_REVIEW)
		else:
			_show_spring_ledger()
		return
	if ChapterTwo.active:
		_investigation.inspect(ChapterTwo.ARCHIVE)
		return
	_investigation.clear_approach_hint()
	if ChapterOne.case_stage == Case.PHOTOGRAPH:
		var box := EvidenceEntry.new()
		box.title = "资料箱 A01"
		box.description = "蓝布报修册和散页已原样放入 A01。把白线和箱卡一起拍下来，和清点位置一并记入笔记。"
		box.preview = ChapterOne.ARCHIVE_PHOTO.preview
		box.preview_scale = ChapterOne.ARCHIVE_PHOTO.preview_scale
		_hud.show_evidence(box, false, "拍下清点照片", _photograph_archive)
	else:
		_hud.show_evidence(ChapterOne.ARCHIVE_PHOTO)


func _show_spring_ledger() -> void:
	var current_book := EvidenceEntry.new()
	current_book.title = "2019 年春季报修册"
	current_book.description = "A01 箱口的蓝布册。封面留着浅色杯圈，书脊完整。翻开后，内页标着「2019 年春季」。"
	current_book.preview = SPRING_LEDGER
	current_book.preview_scale = 6.0
	_hud.show_evidence(current_book, false, "对照首次清点照片", _compare_final_review.bind(current_book))


func _compare_final_review(current_book: EvidenceEntry) -> void:
	var entries: Array[EvidenceEntry] = [ChapterOne.ARCHIVE_PHOTO, current_book]
	_hud.show_comparison(
		entries, "复核 A01", _show_spring_ledger, "返回春册", "提出异议并暂停移交", _pause_handover
	)


func _pause_handover() -> void:
	ChapterThree.pause_handover()
	_hud.show_evidence(FINAL_REVIEW)


func _photograph_archive() -> void:
	ChapterOne.photograph_archive()
	_hud.show_evidence(ChapterOne.ARCHIVE_PHOTO)


func _on_sign_off_requested() -> void:
	if _hud.is_open() or ChapterOne.case_stage != Case.SIGN_OFF:
		return
	_investigation.clear_approach_hint()
	ChapterOne.sign_inventory()
	_hud.show_evidence(ChapterOne.SIGNED_INVENTORY)


func _on_foot_pad_inspected(entry: EvidenceEntry) -> void:
	if ChapterOne.reenactment_stage == Stage.INSTALL_PAD:
		_investigation.inspect(entry, "装回脚垫", _install_pad)
	else:
		_investigation.inspect(entry)


func _on_han_su_interaction_requested() -> void:
	if _hud.is_open() or _reenactment.is_playing():
		return
	_investigation.clear_approach_hint()
	match ChapterOne.reenactment_stage:
		Stage.FIRST_PASS:
			_hud.show_presentation(_reenactment, "第一次过门槛")
			_reenactment.play_pass(false)
		Stage.SECOND_PASS:
			_hud.show_presentation(_reenactment, "第二次过门槛")
			_reenactment.play_pass(true)


func _install_pad() -> void:
	if ChapterOne.reenactment_stage != Stage.INSTALL_PAD or _reenactment.is_playing():
		return
	_hud.show_presentation(_reenactment, "装回脚垫")
	_reenactment.play_installation()


func _on_reenactment_finished() -> void:
	if not _hud.is_open():
		return
	_hud.close_presentation()
	ChapterOne.finish_reenactment_step()
	if ChapterOne.reenactment_stage == Stage.INSTALL_PAD:
		_investigation.show_approach_hint(
			_foot_pad_stand.global_position, "查看门槛内侧掉落的脚垫"
		)
