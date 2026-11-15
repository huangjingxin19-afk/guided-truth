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
const PHOTO_CALL = preload("res://investigation/visitor_photographer_call.tres")
const PHOTO_EXCERPT = preload("res://investigation/visitor_photo_excerpt.tres")
const HANDOVER_NOTICE = preload("res://investigation/handover_notice.tres")
const SPRING_LEDGER = preload("res://investigation/spring_ledger_pickup.tres")
const ACCIDENT_NOTICE = preload("res://investigation/west_stair_accident.tres")
const NIGHT_MESSAGE = preload("res://investigation/chapter_two_night_message.tres")

enum OrderAnswer { FILED_FIRST, PHOTOGRAPHED_FIRST }
enum CandidatePage { LEFT, MIDDLE, RIGHT }
const ORDER_CHOICES := ["先收起原页，再发图", "先发图，再收起原页"]
const PAGE_CHOICES := ["左侧", "中间", "右侧"]

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
	return active and not is_complete() and (has_finding() or (
		InvestigationLog.has_entry(PHOTO.id) and InvestigationLog.has_entry(RECEIPT.id)
	))


func has_finding() -> bool:
	return InvestigationLog.has_entry(FINDING.id)


func can_submit_reasoning() -> bool:
	return (
		can_revisit_102() and not has_finding()
		and InvestigationLog.has_entry(PHOTO_CALL.id)
		and InvestigationLog.has_entry(FILE_POCKET.id)
		and InvestigationLog.has_entry(TRACKS.id)
		and InvestigationLog.has_entry(ARCHIVE.id)
	)


func submit_reasoning(order: int, candidate: int) -> String:
	if not can_submit_reasoning():
		return "请先核对发图经过、前台内袋和 102 的两处对照点。"
	if not OrderAnswer.values().has(order) or not CandidatePage.values().has(candidate):
		return "请各选一项，再提交。"
	if order == OrderAnswer.PHOTOGRAPHED_FIRST and candidate == CandidatePage.MIDDLE:
		InvestigationLog.record(FINDING)
		return ""

	var hint := "对照群消息的发布时间和便签上的收页时间。"
	var review := "收页先后"
	if order == OrderAnswer.PHOTOGRAPHED_FIRST:
		hint = "比一比原图与内袋页角的污渍，再核对日期。"
		review = "原页比对"
	elif candidate != CandidatePage.MIDDLE:
		review = "先后和原页"
	var attempt := EvidenceEntry.new()
	attempt.id = StringName("chapter_two_attempt_%d_%d" % [order, candidate])
	attempt.title = "待复核 · " + review
	attempt.description = "先后：%s。\n候选页：%s。\n\n何青：%s" % [
		ORDER_CHOICES[order], PAGE_CHOICES[candidate], hint,
	]
	InvestigationLog.record(attempt)
	return hint


func has_withdrawn_photo() -> bool:
	return InvestigationLog.has_entry(PHOTO_EXCERPT.id)


func archive_and_withdraw_photo() -> bool:
	if not active or not has_finding():
		return false
	InvestigationLog.replace_with(PHOTO_EXCERPT, [PHOTO.id, FORWARDED_CROP.id])
	return true


func can_document_accident() -> bool:
	return active and InvestigationLog.has_entry(HANDOVER_NOTICE.id)


func can_watch_night_patrol() -> bool:
	return active and InvestigationLog.has_entry(ACCIDENT_NOTICE.id)


func is_complete() -> bool:
	return InvestigationLog.has_entry(NIGHT_MESSAGE.id)


func finish_night_patrol() -> void:
	if can_watch_night_patrol():
		InvestigationLog.record(NIGHT_MESSAGE)


func objective() -> String:
	if is_complete():
		return "第二章已完成 · 回看韩素的夜巡消息"
	if can_watch_night_patrol():
		return "西梯留档已完成 · 到 102 正门回看韩素夜巡"
	if can_document_accident():
		return "去走廊西梯口，拍下旧事故说明"
	if has_withdrawn_photo():
		return "查看前台公告板，记下 102 原地复核的安排"
	if has_finding():
		return "在前台找邵宁确认收页经过"
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
	if not InvestigationLog.has_entry(PHOTO_CALL.id):
		return "在前台找邵宁联系发图人"
	return "回前台向何青提交原页判断"


func status() -> String:
	var time := "周五 17:20"
	if is_complete():
		time = "周五 21:10"
	elif can_document_accident():
		time = "周五 18:45"
	return time + "  ·  " + objective()


func _on_entry_recorded(entry: EvidenceEntry) -> void:
	if active and entry in [
		PHOTO, RECEIPT, FILE_POCKET, TRACKS, ARCHIVE, PHOTO_CALL, FINDING,
		PHOTO_EXCERPT, HANDOVER_NOTICE, SPRING_LEDGER, ACCIDENT_NOTICE, NIGHT_MESSAGE,
	]:
		progress_changed.emit()
