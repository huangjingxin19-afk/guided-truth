extends Node
## Shared progress for the Saturday investigation.

signal progress_changed

const EvidenceEntry = preload("res://investigation/evidence_entry.gd")
const COMMISSION = preload("res://investigation/saturday_commission.tres")
const HIGH_WINDOW = preload("res://investigation/shelter_high_window.tres")
const SUPPLY_ACCESS = preload("res://investigation/saturday_supply_access.tres")
const DESK_VIEW = preload("res://investigation/shelter_desk_view.tres")
const LOCATION_FINDING = preload("res://investigation/shelter_location_finding.tres")
const MESSAGE = preload("res://investigation/shelter_return_message.tres")
const LOAN_CARD = preload("res://investigation/shelter_loan_card.tres")
const RETURN_NOTICE = preload("res://investigation/shelter_return_notice.tres")
const CALL = preload("res://investigation/shelter_appointment_call.tres")
const DUTY_BOARD = preload("res://investigation/shelter_duty_board.tres")
const DEPARTURE = preload("res://investigation/shelter_102_departure.tres")
const RETURNED_STAND = preload("res://investigation/shelter_returned_stand.tres")
const RECEIPT = preload("res://investigation/shelter_signed_receipt.tres")
const CONCLUSION = preload("res://investigation/shelter_conclusion.tres")
const FINAL_REVIEW = preload("res://investigation/final_review_discrepancy.tres")
const G03_CARD = preload("res://investigation/final_g03_card.tres")
const G03_TRACE = preload("res://investigation/final_g03_trace.tres")
const G03_PHOTO = preload("res://investigation/final_g03_photo.tres")
const G03_PERMISSION = preload("res://investigation/final_g03_permission.tres")
const G03_OPEN = preload("res://investigation/final_g03_open.tres")
const AUTUMN_LEDGER = preload("res://investigation/final_autumn_ledger.tres")
const A047_REPORT = preload("res://investigation/final_a047_report.tres")
const A047_REPAIR = preload("res://investigation/final_a047_repair.tres")
const A047_FINDING = preload("res://investigation/final_a047_finding.tres")
const HAN_SU_TESTIMONY = preload("res://investigation/final_han_su_testimony.tres")
const SHAO_NING_TESTIMONY = preload("res://investigation/final_shao_ning_testimony.tres")
const FINAL_BOX_ENTRIES: Array[EvidenceEntry] = [
	G03_CARD, G03_TRACE, G03_PHOTO, G03_PERMISSION, G03_OPEN, AUTUMN_LEDGER,
]
const FINAL_WITNESSES: Array[EvidenceEntry] = [HAN_SU_TESTIMONY, SHAO_NING_TESTIMONY]

const CHAPTER_ENTRIES := [
	COMMISSION, HIGH_WINDOW, SUPPLY_ACCESS, DESK_VIEW, LOCATION_FINDING, MESSAGE,
	LOAN_CARD, RETURN_NOTICE, CALL, DUTY_BOARD, DEPARTURE, RETURNED_STAND, RECEIPT, CONCLUSION,
	FINAL_REVIEW,
	A047_REPORT, A047_REPAIR, A047_FINDING,
]

enum Location { CLASSROOM, SHELTER }
enum Loan { REEL, BLACK_STAND, WHITE_STAND }
enum Visitor { ZHOU_WEN, XU_NAN }
enum AccidentClaim { OUTAGE_TIME, NO_PRIOR_REPORT, FALL_ACCOUNT }
const LOCATION_CHOICES := ["在 102 教室里", "在玻璃外的后院雨棚"]
const LOAN_CHOICES := [
	"12 号电缆卷盘 · 黄色外壳 · 已还",
	"21 号折叠谱架 · 四只黑脚 · 未还",
	"12 号折叠谱架 · 右后脚为白色替换件 · 许南 · 未还",
]
const VISITOR_CHOICES := ["周闻在 102 教室内", "许南在玻璃外的雨棚"]
const RETURN_CHOICES := ["归还 12 号电缆卷盘", "归还 21 号折叠谱架", "归还 12 号白脚谱架"]
const ACCIDENT_CLAIMS := [
	"约 20:17 楼内停电",
	"事发前未收到西梯应急照明故障报告",
	"一名学员离队后于西梯跌落",
]

var active := false
var appointment_started := false
var final_review_started := false
var handover_paused := false


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
	appointment_started = false
	final_review_started = false
	handover_paused = false
	progress_changed.emit()


func can_start_final_review() -> bool:
	return is_complete() and not final_review_started


func start_final_review() -> void:
	if can_start_final_review():
		final_review_started = true
		progress_changed.emit()


func pause_handover() -> void:
	if final_review_started and not handover_paused:
		handover_paused = true
		InvestigationLog.record(FINAL_REVIEW)


func record_final_evidence(entry: EvidenceEntry) -> void:
	if not handover_paused:
		return
	var step := FINAL_BOX_ENTRIES.find(entry)
	if step == -1 and not FINAL_WITNESSES.has(entry):
		return
	if step > 0 and not InvestigationLog.has_entry(FINAL_BOX_ENTRIES[step - 1].id):
		return
	InvestigationLog.record(entry)


func record_a047_report() -> void:
	if handover_paused and InvestigationLog.has_entry(AUTUMN_LEDGER.id):
		InvestigationLog.record(A047_REPORT)


func record_a047_repair() -> void:
	if handover_paused and InvestigationLog.has_entry(A047_REPORT.id):
		InvestigationLog.record(A047_REPAIR)


func needs_accident_photo() -> bool:
	return handover_paused and InvestigationLog.has_entry(A047_REPORT.id) \
		and not InvestigationLog.has_entry(ChapterTwo.ACCIDENT_NOTICE.id)


func submit_accident_comparison(answer: int) -> String:
	if not handover_paused or not InvestigationLog.has_entry(A047_REPORT.id):
		return "先翻看秋册，找到 A-047 报修存根。"
	if needs_accident_photo():
		return "先到走廊西梯口补拍旧事故说明。"
	if answer != AccidentClaim.NO_PRIOR_REPORT:
		return "再比一下 17:52 的签收和 20:17 的事故时间，看看旧说明的哪句话与之冲突。"
	InvestigationLog.record(A047_FINDING)
	return ""


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


func can_check_loan_cards() -> bool:
	return active and InvestigationLog.has_entry(MESSAGE.id) and not InvestigationLog.has_entry(LOAN_CARD.id)


func submit_loan_card(answer: int) -> String:
	if not can_check_loan_cards():
		return "先核对雨棚门铃旁的留言。"
	match answer:
		Loan.WHITE_STAND:
			InvestigationLog.record(LOAN_CARD)
			return ""
		Loan.REEL:
			return "编号是 12。留言还提到了白脚，卷盘上能对上这个特征吗？"
		Loan.BLACK_STAND:
			return "这是谱架。再对一下编号，以及留言提到的白脚。"
		_:
			return "请选择一张借用卡。"


func can_confirm_appointment() -> bool:
	return active and not appointment_started and not observation_pair().is_empty() and has_location_finding() and (
		InvestigationLog.has_entry(MESSAGE.id) and InvestigationLog.has_entry(LOAN_CARD.id)
		and InvestigationLog.has_entry(RETURN_NOTICE.id) and InvestigationLog.has_entry(CALL.id)
		and InvestigationLog.has_entry(DUTY_BOARD.id)
	)


func start_appointment() -> void:
	if can_confirm_appointment():
		appointment_started = true
		progress_changed.emit()


func has_departure_record() -> bool:
	return InvestigationLog.has_entry(DEPARTURE.id)


func can_submit_conclusion() -> bool:
	return appointment_started and has_departure_record() and not observation_pair().is_empty() and has_location_finding() and (
		InvestigationLog.has_entry(MESSAGE.id) and InvestigationLog.has_entry(LOAN_CARD.id)
		and InvestigationLog.has_entry(RETURNED_STAND.id) and InvestigationLog.has_entry(RECEIPT.id)
		and not is_complete()
	)


func submit_conclusion(visitor: int, item: int) -> String:
	if not can_submit_conclusion():
		return "等签收手续办完，再把查到的线索合在一起。"
	if visitor != Visitor.XU_NAN:
		return "两张近景里是周闻在量凳子。把站位、借用卡和来归还的人对照一下。"
	if item != Loan.WHITE_STAND:
		return "再核对留言、借用卡和签收联上的编号、品类、右后脚。"
	InvestigationLog.record(CONCLUSION)
	return ""


func is_complete() -> bool:
	return InvestigationLog.has_entry(CONCLUSION.id)


func status() -> String:
	var time := "17:50"
	if final_review_started:
		time = "19:28"
	elif InvestigationLog.has_entry(RECEIPT.id):
		time = "19:27"
	elif appointment_started:
		time = "19:25"
	return "周六 " + time + "  ·  " + _objective()


func _objective() -> String:
	if handover_paused:
		if InvestigationLog.has_entry(A047_FINDING.id):
			return "旧事故说明已核对，可在笔记回看结论"
		if needs_accident_photo():
			return "去走廊西梯口补拍旧事故说明"
		if InvestigationLog.has_entry(A047_REPORT.id):
			return "回到 102 翻看秋册，对照旧事故说明"
		if InvestigationLog.has_entry(AUTUMN_LEDGER.id):
			return "秋册已找回，翻看目录里的西梯应急灯报修"
		if InvestigationLog.has_entry(G03_OPEN.id):
			return "移开 G03 里的谱架，取出秋册"
		if InvestigationLog.has_entry(G03_PERMISSION.id):
			return "回到 G03，在何青见证下开箱"
		if InvestigationLog.has_entry(G03_PHOTO.id):
			return "带着开箱前照片，请何青见证开箱"
		return "绕过长桌右端，检查桌后的 G03"
	if final_review_started:
		return "对照首次清点照片，检查 A01 里的报修册"
	if is_complete():
		return "第三章已结案，可回看三章笔记"
	if can_submit_conclusion():
		return "根据笔记向韩素提交归还结论"
	if InvestigationLog.has_entry(RETURNED_STAND.id):
		return "请韩素在借用卡上签收，留存签收联"
	if has_departure_record():
		return "随韩素到后院，核对许南送回的谱架"
	if appointment_started:
		return "离开 102 前，到桌后记下 A01、桌脚和 G03 的状态"
	if can_confirm_appointment():
		return "查看前台值班板，确认 19:25 赴约"
	if InvestigationLog.has_entry(CALL.id):
		return "把双方商定的时间和地点写入值班板"
	if InvestigationLog.has_entry(RETURN_NOTICE.id):
		return "把交回通知出示给前台的韩素"
	if InvestigationLog.has_entry(LOAN_CARD.id):
		return "查看周闻拿来的借用物交回通知"
	if can_check_loan_cards():
		return "到前台，把留言与三张借用卡对照"
	if has_location_finding():
		return "到后院雨棚，检查门铃旁的留言盒"
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
	if active and (entry in CHAPTER_ENTRIES or entry in FINAL_BOX_ENTRIES or entry in FINAL_WITNESSES):
		progress_changed.emit()
