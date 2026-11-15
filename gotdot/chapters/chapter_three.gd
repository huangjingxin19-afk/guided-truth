extends Node
## Shared progress for the Saturday investigation.

signal progress_changed

const EvidenceEntry = preload("res://investigation/evidence_entry.gd")
const COMMISSION = preload("res://investigation/saturday_commission.tres")
const HIGH_WINDOW = preload("res://investigation/shelter_high_window.tres")
const SUPPLY_ACCESS = preload("res://investigation/saturday_supply_access.tres")
const DESK_VIEW = preload("res://investigation/shelter_desk_view.tres")
const LOCATION_FINDING = preload("res://investigation/shelter_location_finding.tres")

enum Location { CLASSROOM, SHELTER }
const LOCATION_CHOICES := ["在 102 教室里", "在玻璃外的后院雨棚"]

var active := false


func _ready() -> void:
	InvestigationLog.entry_recorded.connect(_on_entry_recorded)


func can_start() -> bool:
	return not active and ChapterTwo.is_complete()


func start() -> void:
	if can_start():
		active = true
		progress_changed.emit()


func reset() -> void:
	active = false
	progress_changed.emit()


func can_observe_high_window() -> bool:
	return active and InvestigationLog.has_entry(COMMISSION.id)


func can_open_supply_door() -> bool:
	return active and InvestigationLog.has_entry(HIGH_WINDOW.id)


func can_enter_supply_door() -> bool:
	return active and InvestigationLog.has_entry(SUPPLY_ACCESS.id)


func observation_pair() -> Array[EvidenceEntry]:
	if active and InvestigationLog.has_entry(HIGH_WINDOW.id) and InvestigationLog.has_entry(DESK_VIEW.id):
		return [HIGH_WINDOW, DESK_VIEW]
	return []


func has_location_finding() -> bool:
	return InvestigationLog.has_entry(LOCATION_FINDING.id)


func can_submit_location() -> bool:
	return not has_location_finding() and not observation_pair().is_empty()


func submit_location(answer: int) -> String:
	if not can_submit_location():
		return "先从高窗和桌后各看一次。"
	match answer:
		Location.SHELTER:
			InvestigationLog.record(LOCATION_FINDING)
			return ""
		Location.CLASSROOM:
			return "再比一下桌后看到的玻璃边框和人影脚下的地面。"
		_:
			return "请先选一个位置。"


func status() -> String:
	return "周六 17:50  ·  " + _objective()


func _objective() -> String:
	if has_location_finding():
		return "已确认人影站位 · 可回看两处观察"
	if can_submit_location():
		return "从后院绕回走廊，向韩素说明人影的位置"
	if can_enter_supply_door():
		return "从器材门进 102，绕到长桌后看玻璃隔断"
	if can_open_supply_door():
		return "从外廊去后院，请韩素打开器材门"
	if can_observe_high_window():
		return "靠近 102 正门，从高窗观察"
	return "去 102 正门旁找韩素"


func _on_entry_recorded(entry: EvidenceEntry) -> void:
	if active and entry in [COMMISSION, HIGH_WINDOW, SUPPLY_ACCESS, DESK_VIEW, LOCATION_FINDING]:
		progress_changed.emit()
