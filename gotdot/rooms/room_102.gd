extends Node2D

const EvidenceEntry = preload("res://investigation/evidence_entry.gd")
const InvestigationHud = preload("res://ui/investigation_hud.gd")
const RoomInvestigation = preload("res://investigation/room_investigation.gd")
const ThresholdReenactment = preload("res://rooms/room_102_threshold_reenactment.gd")
const Stage = preload("res://chapters/chapter_one.gd").ReenactmentStage

@onready var _investigation: RoomInvestigation = $Investigation
@onready var _hud: InvestigationHud = $InvestigationHud
@onready var _reenactment: ThresholdReenactment = $ThresholdReenactment
@onready var _foot_pad: Node2D = $Scenery/FootPad
@onready var _foot_pad_point: Button = $Investigation/FootPadPoint
@onready var _han_su_point: Button = $Investigation/HanSuPoint
@onready var _foot_pad_stand: Marker2D = $Investigation/FootPadStand

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
