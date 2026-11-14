extends Node
## First-chapter progress lives outside rooms; room changes never reset it.

signal progress_changed

const COMMISSION = preload("res://investigation/chapter_one_commission.tres")
const EQUIPMENT_NOTE = preload("res://investigation/equipment_note.tres")
const SEAL = preload("res://investigation/front_door_seal.tres")

var commission_accepted := false
var corridor_visited := false


func reset() -> void:
	commission_accepted = false
	corridor_visited = false
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


func objective() -> String:
	if not commission_accepted:
		return "靠近何青，领取 102 的调查委托"
	if not InvestigationLog.has_entry(SEAL.id):
		return "前往走廊，查看 102 正门封条"
	return "封条已登记 · 下一步：绕后院核对器材取用"


func story_time() -> String:
	return "周四 18:40" if corridor_visited else "周四 18:35"
