extends Node
## First-chapter progress lives outside rooms; room changes never reset it.

signal progress_changed

const COMMISSION = preload("res://investigation/chapter_one_commission.tres")
const EQUIPMENT_NOTE = preload("res://investigation/equipment_note.tres")
const SEAL = preload("res://investigation/front_door_seal.tres")
const AUTHORIZATION = preload("res://investigation/back_door_authorization.tres")
const CART_SHEET = preload("res://investigation/cart_checkout.tres")
const REENACTMENT = preload("res://investigation/cart_reenactment.tres")

enum ReenactmentStage { FIRST_PASS, INSTALL_PAD, SECOND_PASS, COMPLETE }

var commission_accepted := false
var corridor_visited := false
var reenactment_stage := ReenactmentStage.FIRST_PASS


func reset() -> void:
	commission_accepted = false
	corridor_visited = false
	reenactment_stage = ReenactmentStage.FIRST_PASS
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


func objective() -> String:
	if not commission_accepted:
		return "靠近何青，领取 102 的调查委托"
	if not can_enter_supply_door():
		if InvestigationLog.has_entry(SEAL.id):
			return "封条已登记 · 绕外廊去后院找韩素"
		return "查看 102 正门封条，或绕外廊去后院"
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
	return "取用记录与推车复走已核对"


func story_time() -> String:
	return "周四 18:40" if corridor_visited else "周四 18:35"
