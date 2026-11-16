extends Node2D

const EvidenceEntry = preload("res://investigation/evidence_entry.gd")
const HanSuActor = preload("res://actors/han_su.gd")
const InvestigationHud = preload("res://ui/investigation_hud.gd")
const RoomInvestigation = preload("res://investigation/room_investigation.gd")
const ThresholdReenactment = preload("res://rooms/room_102_threshold_reenactment.gd")
const Reasoning = preload("res://ui/reasoning_form.gd")
const FinalReasoning = preload("res://chapters/final_reasoning.gd")
const FinalReasoningView = preload("res://ui/final_reasoning_view.gd")
const FinalEnding = preload("res://ui/final_ending.gd")
const WalkableFloor = preload("res://rooms/walkable_floor.gd")
const Stage = preload("res://chapters/chapter_one.gd").ReenactmentStage
const Case = preload("res://chapters/chapter_one.gd").CaseStage
const LEDGER = preload("res://props/repair_ledger.tscn")
const SPRING_LEDGER = preload("res://props/spring_repair_ledger.tscn")
const FINAL_REVIEW = preload("res://investigation/final_review_discrepancy.tres")
const DESK_SHIFT := Vector2(0, 28)
const ACCIDENT_EXCERPTS: Array[String] = [
	"11 月 8 日 17:40 报修\n17:52 周闻签收\n「今晚西梯照常走，明早再修。」",
	"11 月 8 日约 20:17 楼内停电\n「事发前未收到西梯应急照明故障报告。」",
]

var _final_reasoning := FinalReasoningView.new()
var _final_ending := FinalEnding.new()

@onready var _investigation: RoomInvestigation = $Investigation
@onready var _hud: InvestigationHud = $InvestigationHud
@onready var _reenactment: ThresholdReenactment = $ThresholdReenactment
@onready var _foot_pad: Node2D = $Scenery/FootPad
@onready var _foot_pad_point: Button = $Investigation/FootPadPoint
@onready var _han_su_point: Button = $Investigation/HanSuPoint
@onready var _foot_pad_stand: Marker2D = $Investigation/FootPadStand
@onready var _reasoning: Reasoning = $Reasoning
@onready var _accident_reasoning: Reasoning = $FinalAccidentReasoning
@onready var _floor: WalkableFloor = $WalkableFloor
@onready var _desk: StaticBody2D = $WalkableFloor/DepthSort/LongDesk
@onready var _desk_start := _desk.position


func _ready() -> void:
	_reasoning.setup(ChapterOne.ROUTE_CHOICES, ChapterOne.SOUND_CHOICES)
	_accident_reasoning.setup(ChapterThree.ACCIDENT_CLAIMS)
	_final_reasoning.name = "FinalReasoningView"
	_final_reasoning.hide()
	add_child(_final_reasoning)
	_final_reasoning.request_group.connect(_show_final_group)
	_final_reasoning.submit_group.connect(_submit_final_group)
	_final_reasoning.request_entry.connect(_review_final_proof)
	_final_reasoning.hint_requested.connect(_show_final_hint)
	_final_reasoning.request_motive.connect(_show_final_motive)
	_final_reasoning.submit_motive.connect(_submit_final_motive)
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
	var has_ledger := _has_final_entry(ChapterThree.AUTUMN_LEDGER)
	$Investigation/FinalHeQingPoint.interaction_label = "向何青核对正门封条" if has_ledger else "请打开 G03"
	$Investigation/FinalHeQingPoint.approach_hint = "走到何青身边，核对正门封条" if has_ledger else "走到何青身边，请她打开 G03"
	$Investigation/FinalHanSuPoint.interaction_label = "向韩素核对离场情况"
	$Investigation/FinalReasoningPoint.visible = ChapterThree.can_submit_final_reasoning()
	_desk.get_node("FinalDeskNotes").visible = $Investigation/FinalReasoningPoint.visible
	var desk_action := "把三天的事放在一起"
	if _has_final_entry(ChapterThree.CONFRONTATION):
		desk_action = "回看周闻对质"
	elif _has_final_entry(FinalReasoning.MOTIVE):
		desk_action = "与周闻对质"
	$Investigation/FinalReasoningPoint.interaction_label = desk_action
	$Scenery/ZhouWen.hide()
	$Scenery/FinalZhouWen.show()
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
		_show_autumn_ledger()
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
	if _has_final_entry(ChapterThree.AUTUMN_LEDGER):
		ChapterThree.record_final_evidence(ChapterThree.SEAL_CONFIRMATION)
		_hud.show_evidence(ChapterThree.SEAL_CONFIRMATION)
	elif _has_final_entry(ChapterThree.G03_PHOTO):
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
	_show_autumn_ledger()


func _show_autumn_ledger() -> void:
	_hud.show_evidence(ChapterThree.AUTUMN_LEDGER, false, "翻看目录", _show_autumn_directory)


func _show_autumn_directory() -> void:
	var directory := EvidenceEntry.new()
	directory.title = "2019 年秋季报修册目录"
	directory.description = "按报修地点查找\n\n一楼  ·  大厅及前台\n二楼  ·  西梯二层应急灯    A-047\n三楼  ·  排练室"
	_hud.show_evidence(directory, false, "打开 A-047", _show_a047_report)


func _show_a047_report() -> void:
	ChapterThree.record_a047_report()
	_hud.show_evidence(
		ChapterThree.A047_REPORT, false, "对照旧事故说明", _compare_accident_records,
		"翻到次日维修记录", _show_a047_repair
	)


func _show_a047_repair() -> void:
	ChapterThree.record_a047_repair()
	_hud.show_evidence(ChapterThree.A047_REPAIR, false, "返回 A-047", _show_a047_report)


func _compare_accident_records() -> void:
	if ChapterThree.needs_accident_photo():
		var reminder := EvidenceEntry.new()
		reminder.title = "补拍旧事故说明"
		reminder.description = "笔记里还没有旧事故说明的照片。从器材门经后院回走廊，到西梯口的公告板补拍。"
		_hud.show_evidence(reminder, false, "返回 A-047", _show_a047_report)
		return
	var entries: Array[EvidenceEntry] = [ChapterThree.A047_REPORT, ChapterTwo.ACCIDENT_NOTICE]
	var submit := Callable()
	if not _has_final_entry(ChapterThree.A047_FINDING):
		submit = _show_accident_reasoning
	_hud.show_comparison(
		entries, "核对旧事故说明", _show_a047_report, "返回 A-047",
		"指出有误的一句", submit, ACCIDENT_EXCERPTS
	)


func _show_accident_reasoning() -> void:
	_accident_reasoning.clear_feedback()
	_hud.show_presentation(
		_accident_reasoning, "核对旧事故说明", true, _compare_accident_records, "返回对照"
	)


func _on_accident_reasoning_submitted(answer: int, _unused: int) -> void:
	var feedback := ChapterThree.submit_accident_comparison(answer)
	if feedback.is_empty():
		_hud.show_evidence(ChapterThree.A047_FINDING)
	else:
		_accident_reasoning.show_feedback(feedback)


func _on_final_reasoning_requested() -> void:
	if _hud.is_open() or not ChapterThree.can_submit_final_reasoning():
		return
	_investigation.clear_approach_hint()
	if _has_final_entry(FinalReasoning.MOTIVE):
		_show_confrontation()
	else:
		_show_final_menu()


func _show_final_menu() -> void:
	var groups: Array[Dictionary] = []
	for group in FinalReasoning.CASES.size():
		groups.append({
			"id": group,
			"title": FinalReasoning.CASES[group].title,
			"completed": _has_final_entry(FinalReasoning.FINDINGS[group]),
		})
	_final_reasoning.show_group_menu(groups)
	_show_final_form()


func _show_final_form(in_group := false) -> void:
	_hud.show_presentation(
		_final_reasoning, "把三天的事放在一起", true,
		_show_final_menu if in_group else Callable(), "返回分组" if in_group else "关闭"
	)


func _show_final_group(group: int) -> void:
	if group == -1:
		_show_final_menu()
		return
	var finding: EvidenceEntry = FinalReasoning.FINDINGS[group]
	if _has_final_entry(finding):
		_hud.show_evidence(finding, false, "返回分组", _show_final_menu)
		return
	var notes := ChapterThree.final_evidence_ids()
	var available: Array[StringName] = []
	var proofs: Array[Dictionary] = []
	proofs.assign(FinalReasoning.PROOFS)
	for proof in proofs:
		if FinalReasoning.proof_is_available(proof, notes):
			available.append(proof.key)
	var current: Dictionary = FinalReasoning.CASES[group]
	var changes: Array[String] = []
	changes.assign(current.changes)
	_final_reasoning.show_group(group, current.title, changes, proofs, available)
	if not FinalReasoning.proof_is_available(FinalReasoning.PROOFS[current.proof], notes):
		_final_reasoning.show_feedback(FinalReasoning.missing_proof_hint(group, notes), true, true)
	_show_final_form(true)


func _show_final_hint(group: int) -> void:
	var current: Dictionary = FinalReasoning.CASES[group]
	var notes := ChapterThree.final_evidence_ids()
	var hint: String = current.hint
	if not FinalReasoning.proof_is_available(FinalReasoning.PROOFS[current.proof], notes):
		hint += "\n" + FinalReasoning.missing_proof_hint(group, notes)
	_final_reasoning.show_feedback(hint, true, true)


func _review_final_proof(key: StringName) -> void:
	for proof: Dictionary in FinalReasoning.PROOFS:
		if proof.key == key:
			var records: Array[EvidenceEntry] = InvestigationLog.entries().filter(
				func(entry: EvidenceEntry) -> bool:
					return entry.id in proof.required or entry.id in proof.get("alternatives", [])
			)
			_hud.show_notebook(records, [], _show_final_form.bind(true))
			return


func _submit_final_group(group: int, change: int, proof: int) -> void:
	var feedback := ChapterThree.submit_final_group(group, change, proof)
	if feedback.is_empty():
		_hud.show_evidence(FinalReasoning.FINDINGS[group], false, "返回分组", _show_final_menu)
	else:
		_final_reasoning.show_feedback(feedback)


func _show_final_motive() -> void:
	var claims: Array[String] = []
	claims.assign(ChapterThree.ACCIDENT_CLAIMS)
	_final_reasoning.show_motive(FinalReasoning.MOTIVE_ITEMS, claims)
	_show_final_form(true)


func _submit_final_motive(item: int, claim: int) -> void:
	var feedback := ChapterThree.submit_final_motive(item, claim)
	if feedback.is_empty():
		_hud.show_evidence(FinalReasoning.MOTIVE, false, "与周闻对质", _show_confrontation)
	else:
		_final_reasoning.show_feedback(feedback, true, true)


func _show_confrontation() -> void:
	_final_ending.show_confrontation(_hud, ChapterThree.record_ending, _go_to_epilogue)


func _go_to_epilogue() -> void:
	RoomTransition.change_room("res://rooms/back_yard.tscn", &"FromRoom102")


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
