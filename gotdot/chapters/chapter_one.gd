extends Node
## First-chapter progress lives outside rooms; room changes never reset it.

signal progress_changed

const COMMISSION = preload("res://investigation/chapter_one_commission.tres")
const EQUIPMENT_NOTE = preload("res://investigation/equipment_note.tres")
const SEAL = preload("res://investigation/front_door_seal.tres")
const AUTHORIZATION = preload("res://investigation/back_door_authorization.tres")
const CART_SHEET = preload("res://investigation/cart_checkout.tres")
const REENACTMENT = preload("res://investigation/cart_reenactment.tres")
const CONCLUSION = preload("res://investigation/chapter_one_conclusion.tres")
const ARCHIVE_PHOTO = preload("res://investigation/a01_archive_photo.tres")
const SIGNED_INVENTORY = preload("res://investigation/a01_signed_inventory.tres")

const EvidenceEntry = preload("res://investigation/evidence_entry.gd")

enum RouteAnswer { FRONT_DOOR, SUPPLY_DOOR }
enum SoundAnswer { STOOL_FOOT, WHEEL }
const ROUTE_CHOICES := ["有人从正门搬走资料", "韩素从器材门领回折叠凳"]
const SOUND_CHOICES := ["凳脚擦过推车铁板", "车轮磕过门槛"]

enum ReenactmentStage { FIRST_PASS, INSTALL_PAD, SECOND_PASS, COMPLETE }
enum CaseStage { DEDUCTION, DRAWER, PACK_ARCHIVE, PHOTOGRAPH, SIGN_OFF, EPILOGUE, COMPLETE }

var commission_accepted := false
var corridor_visited := false
var reenactment_stage := ReenactmentStage.FIRST_PASS
var case_stage := CaseStage.DEDUCTION


func reset() -> void:
	commission_accepted = false
	corridor_visited = false
	reenactment_stage = ReenactmentStage.FIRST_PASS
	case_stage = CaseStage.DEDUCTION
	progress_changed.emit()


func accept_commission() -> void:
	if commission_accepted:
		return
	commission_accepted = true
	InvestigationLog.record(COMMISSION)
	InvestigationLog.record(EQUIPMENT_NOTE)
	progress_changed.emit()


func visit_corridor() -> void:
	if commission_accepted and not corridor_visited:
		corridor_visited = true
		progress_changed.emit()


func inspect_seal() -> bool:
	if not commission_accepted:
		return false
	InvestigationLog.record(SEAL)
	progress_changed.emit()
	return true


func can_enter_supply_door() -> bool:
	return commission_accepted and InvestigationLog.has_entry(AUTHORIZATION.id)


func finish_reenactment_step() -> void:
	match reenactment_stage:
		ReenactmentStage.FIRST_PASS:
			reenactment_stage = ReenactmentStage.INSTALL_PAD
		ReenactmentStage.INSTALL_PAD:
			reenactment_stage = ReenactmentStage.SECOND_PASS
		ReenactmentStage.SECOND_PASS:
			reenactment_stage = ReenactmentStage.COMPLETE
			InvestigationLog.record(REENACTMENT)
		ReenactmentStage.COMPLETE:
			return
	progress_changed.emit()


func can_submit_reasoning() -> bool:
	return (
		case_stage == CaseStage.DEDUCTION
		and can_enter_supply_door()
		and reenactment_stage == ReenactmentStage.COMPLETE
		and InvestigationLog.has_entry(SEAL.id)
		and InvestigationLog.has_entry(CART_SHEET.id)
	)


func is_he_qing_in_102() -> bool:
	return can_submit_reasoning() or (case_stage >= CaseStage.DRAWER and case_stage < CaseStage.EPILOGUE)


func submit_reasoning(route: int, sound: int) -> String:
	if not can_submit_reasoning():
		return "请先补齐出入记录和复走对照。"
	if not RouteAnswer.values().has(route) or not SoundAnswer.values().has(sound):
		return "请各选一项，再提交。"
	if route == RouteAnswer.SUPPLY_DOOR and sound == SoundAnswer.STOOL_FOOT:
		InvestigationLog.record(CONCLUSION)
		_advance_case(CaseStage.DRAWER)
		return ""

	var hint := "再对照两次过槛，哪一段声响消失了？"
	var review := "拖响来源"
	if route != RouteAnswer.SUPPLY_DOOR:
		hint = "再核对封条、后门授权和随车单。"
		review = "出入路线" if sound == SoundAnswer.STOOL_FOOT else "出入路线和声响"
	var attempt := EvidenceEntry.new()
	attempt.id = StringName("chapter_one_attempt_%d_%d" % [route, sound])
	attempt.title = "待复核 · " + review
	attempt.description = "路线：%s。\n声响：%s。\n\n何青：%s" % [
		ROUTE_CHOICES[route], SOUND_CHOICES[sound], hint,
	]
	InvestigationLog.record(attempt)
	return hint


func open_drawer() -> void:
	if case_stage == CaseStage.DRAWER:
		_advance_case(CaseStage.PACK_ARCHIVE)


func pack_archive() -> void:
	if case_stage == CaseStage.PACK_ARCHIVE:
		_advance_case(CaseStage.PHOTOGRAPH)


func photograph_archive() -> void:
	if case_stage == CaseStage.PHOTOGRAPH:
		InvestigationLog.record(ARCHIVE_PHOTO)
		_advance_case(CaseStage.SIGN_OFF)


func sign_inventory() -> void:
	if case_stage == CaseStage.SIGN_OFF:
		InvestigationLog.record(SIGNED_INVENTORY)
		_advance_case(CaseStage.EPILOGUE)


func finish_chapter() -> void:
	if case_stage == CaseStage.EPILOGUE:
		_advance_case(CaseStage.COMPLETE)


func _advance_case(stage: CaseStage) -> void:
	case_stage = stage
	progress_changed.emit()


func objective() -> String:
	if not commission_accepted:
		return "靠近何青，领取 102 的调查委托"
	if not can_enter_supply_door():
		if InvestigationLog.has_entry(SEAL.id):
			return "封条已登记 · 绕外廊去后院找韩素"
		return "查看 102 正门封条，或绕外廊去后院"
	match case_stage:
		CaseStage.DRAWER:
			return "在 102 绕到长桌背后，查看抽屉柜最下格"
		CaseStage.PACK_ARCHIVE:
			return "将蓝布报修册和散页装入 A01"
		CaseStage.PHOTOGRAPH:
			return "查看 A01，拍下册子的白线和箱卡"
		CaseStage.SIGN_OFF:
			return "请 102 里的周闻在清点单上签署「已阅」"
		CaseStage.EPILOGUE:
			return "经后院回到走廊，再看一眼 102 正门"
		CaseStage.COMPLETE:
			return "第一章《上锁的教室》已完成"
	match reenactment_stage:
		ReenactmentStage.FIRST_PASS:
			return "从器材门进入 102，找韩素看推车过槛"
		ReenactmentStage.INSTALL_PAD:
			return "查看器材门内侧掉落的脚垫，装回凳脚"
		ReenactmentStage.SECOND_PASS:
			return "找韩素再推一次，比较装垫前后的声响"
	if not InvestigationLog.has_entry(SEAL.id):
		return "复走已记录 · 回走廊补查 102 正门封条"
	if not InvestigationLog.has_entry(CART_SHEET.id):
		return "复走已记录 · 回后院查看推车上的随车单"
	return "证据已齐 · 在 102 向何青提交推理"


func story_time() -> String:
	return "周四 18:40" if corridor_visited else "周四 18:35"
