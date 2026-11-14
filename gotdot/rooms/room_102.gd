extends Node2D

const EvidenceEntry = preload("res://investigation/evidence_entry.gd")
const InvestigationHud = preload("res://ui/investigation_hud.gd")
const RoomInvestigation = preload("res://investigation/room_investigation.gd")
const ThresholdReenactment = preload("res://rooms/room_102_threshold_reenactment.gd")
const REENACTMENT = preload("res://investigation/cart_reenactment.tres")

enum Stage { FIRST_PASS, INSTALL_PAD, SECOND_PASS, COMPLETE }

@onready var _investigation: RoomInvestigation = $Investigation
@onready var _hud: InvestigationHud = $InvestigationHud
@onready var _reenactment: ThresholdReenactment = $ThresholdReenactment
@onready var _foot_pad: Node2D = $Scenery/FootPad
@onready var _foot_pad_point: Button = $Investigation/FootPadPoint
@onready var _han_su_point: Button = $Investigation/HanSuPoint
@onready var _foot_pad_stand: Marker2D = $Investigation/FootPadStand

var _stage := Stage.FIRST_PASS


func _on_foot_pad_inspected(entry: EvidenceEntry) -> void:
	if _stage == Stage.INSTALL_PAD:
		_investigation.inspect(entry, "装回脚垫", _install_pad)
	else:
		_investigation.inspect(entry)


func _on_han_su_interaction_requested() -> void:
	if _hud.is_open() or _reenactment.is_playing():
		return
	_investigation.clear_approach_hint()
	match _stage:
		Stage.FIRST_PASS:
			_hud.show_presentation(_reenactment, "第一次过门槛")
			_reenactment.play_pass(false)
		Stage.SECOND_PASS:
			_hud.show_presentation(_reenactment, "第二次过门槛")
			_reenactment.play_pass(true)


func _install_pad() -> void:
	if _stage != Stage.INSTALL_PAD or _reenactment.is_playing():
		return
	_hud.show_presentation(_reenactment, "装回脚垫")
	_reenactment.play_installation()


func _on_reenactment_finished() -> void:
	_hud.close_presentation()
	match _stage:
		Stage.FIRST_PASS:
			_stage = Stage.INSTALL_PAD
			_han_su_point.hide()
			_investigation.show_approach_hint(
				_foot_pad_stand.global_position, "查看门槛内侧掉落的脚垫"
			)
		Stage.INSTALL_PAD:
			_stage = Stage.SECOND_PASS
			_foot_pad.hide()
			_foot_pad_point.hide()
			_han_su_point.text = "再推一次"
			_han_su_point.show()
		Stage.SECOND_PASS:
			_stage = Stage.COMPLETE
			_han_su_point.hide()
			InvestigationLog.record(REENACTMENT)
