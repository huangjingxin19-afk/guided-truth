extends Node
## Shared progress for the Friday investigation.

signal progress_changed

const EvidenceEntry = preload("res://investigation/evidence_entry.gd")
const PHOTO = preload("res://investigation/visitor_chat_photo.tres")
const FORWARDED_CROP = preload("res://investigation/visitor_forwarded_crop.tres")
const RECEIPT = preload("res://investigation/visitor_receipt_note.tres")
const FILE_POCKET = preload("res://investigation/visitor_file_pocket.tres")
const TRACKS = preload("res://investigation/room_102_revisit_tracks.tres")
const ARCHIVE = preload("res://investigation/room_102_revisit_archive.tres")
const FINDING = preload("res://investigation/chapter_two_page_finding.tres")

enum OrderAnswer { FILED_FIRST, PHOTOGRAPHED_FIRST }
enum LocationAnswer { ARCHIVE_BOX, FRONT_DESK_POCKET }
const ORDER_CHOICES := ["先收起原页，再发图", "先发图，再收起原页"]
const LOCATION_CHOICES := ["102 的 A01 资料箱", "前台内袋的周四页"]

var active := false


func _ready() -> void:
	InvestigationLog.entry_recorded.connect(_on_entry_recorded)


func can_start() -> bool:
	return not active and ChapterOne.case_stage == ChapterOne.CaseStage.COMPLETE


func start() -> void:
	if can_start():
		active = true
		progress_changed.emit()


func reset() -> void:
	active = false
	progress_changed.emit()


func can_revisit_102() -> bool:
	return active and InvestigationLog.has_entry(PHOTO.id) and InvestigationLog.has_entry(RECEIPT.id)


func has_finding() -> bool:
	return InvestigationLog.has_entry(FINDING.id)


func can_submit_reasoning() -> bool:
	return (
		can_revisit_102() and not has_finding()
		and InvestigationLog.has_entry(FILE_POCKET.id)
		and InvestigationLog.has_entry(TRACKS.id)
		and InvestigationLog.has_entry(ARCHIVE.id)
	)


func submit_reasoning(order: int, location: int) -> String:
	if not can_submit_reasoning():
		return "请先查完前台内袋和 102 的两处对照点。"
	if not OrderAnswer.values().has(order) or not LocationAnswer.values().has(location):
		return "请各选一项，再提交。"
	if order == OrderAnswer.PHOTOGRAPHED_FIRST and location == LocationAnswer.FRONT_DESK_POCKET:
		InvestigationLog.record(FINDING)
		return ""

	var hint := "对照群消息的发布时间和便签上的收页时间。"
	var review := "收页先后"
	if order == OrderAnswer.PHOTOGRAPHED_FIRST:
		hint = "比一比原图与内袋页角的污渍，再看看 A01 清点记录里的纸从哪来。"
		review = "原页去向"
	elif location != LocationAnswer.FRONT_DESK_POCKET:
		review = "先后和去向"
	var attempt := EvidenceEntry.new()
	attempt.id = StringName("chapter_two_attempt_%d_%d" % [order, location])
	attempt.title = "待复核 · " + review
	attempt.description = "先后：%s。\n去向：%s。\n\n何青：%s" % [
		ORDER_CHOICES[order], LOCATION_CHOICES[location], hint,
	]
	InvestigationLog.record(attempt)
	return hint


func objective() -> String:
	if not InvestigationLog.has_entry(PHOTO.id):
		return "周四访客页不见了 · 查柜台手机上 16:46 的群聊原图"
	if not InvestigationLog.has_entry(RECEIPT.id):
		return "在柜台查看 16:50 收页便签"
	if not InvestigationLog.has_entry(TRACKS.id):
		return "经走廊和后院进 102，查看器材门内侧的旧轮痕"
	if not InvestigationLog.has_entry(ARCHIVE.id):
		return "沿 102 的轮痕绕到长桌背后，核对 A01"
	if not InvestigationLog.has_entry(FILE_POCKET.id):
		return "回前台，绕到柜台右端查看登记夹和内袋"
	if not has_finding():
		return "回前台向何青提交原页去向判断"
	return "原页去向已核对"


func status() -> String:
	return "周五 17:20  ·  " + objective()


func _on_entry_recorded(entry: EvidenceEntry) -> void:
	if active and entry in [PHOTO, RECEIPT, FILE_POCKET, TRACKS, ARCHIVE, FINDING]:
		progress_changed.emit()
