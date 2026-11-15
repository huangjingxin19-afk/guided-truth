extends Node2D

const EvidenceEntry = preload("res://investigation/evidence_entry.gd")
const InvestigationHud = preload("res://ui/investigation_hud.gd")
const RoomInvestigation = preload("res://investigation/room_investigation.gd")
const ThresholdReenactment = preload("res://rooms/room_102_threshold_reenactment.gd")
const Reasoning = preload("res://ui/chapter_one_reasoning.gd")
const WalkableFloor = preload("res://rooms/walkable_floor.gd")
const Stage = preload("res://chapters/chapter_one.gd").ReenactmentStage
const Case = preload("res://chapters/chapter_one.gd").CaseStage
const LEDGER = preload("res://props/repair_ledger.tscn")
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
	ChapterOne.progress_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
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

	var desk_position := _desk_start + DESK_SHIFT if stage >= Case.PACK_ARCHIVE else _desk_start
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
		_reasoning.show_feedback(feedback)


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
