extends RefCounted
## Presents the ending in the room HUDs. Only signed or completed actions are saved.

const EvidenceEntry = preload("res://investigation/evidence_entry.gd")
const InvestigationHud = preload("res://ui/investigation_hud.gd")
const CONFRONTATION = preload("res://investigation/final_ending_confrontation.tres")
const TESTIMONY = preload("res://investigation/final_ending_testimony.tres")
const CORRECTION = preload("res://investigation/final_ending_correction.tres")
const COMPLETE = preload("res://investigation/final_ending_complete.tres")
const STEADY_STAND = preload("res://ui/final_ending_stand.tscn")
const STRAIGHTEN_PEN = preload("res://ui/final_ending_pen.tscn")


func show_confrontation(hud: InvestigationHud, record_ending: Callable, go_to_epilogue: Callable) -> void:
	if InvestigationLog.has_entry(CONFRONTATION.id):
		_show_retention_record(hud, record_ending, go_to_epilogue)
	else:
		_show_confrontation_opening(hud, record_ending, go_to_epilogue)


func _show_confrontation_opening(
	hud: InvestigationHud, record_ending: Callable, go_to_epilogue: Callable
) -> void:
	var page := _page("周闻把笔放下",
		"林禾把春册留在 A01 旁，把秋册放在原始清点照片上。何青站在桌边。周闻伸手，只把签字板上的笔摆正。\n\n"
		+ "林禾：「你周四问的是清点单，周五收了春册。今晚你等韩老师出去，把她缝过的那本塞到了谱架底下。」\n"
		+ "周闻：「我看见你写一册。接手的人也只看那一行。」"
	)
	page.preview = STRAIGHTEN_PEN
	page.preview_scale = 1.12
	hud.show_evidence(page, false, "问起那张便笺", _show_confrontation_answer.bind(hud, record_ending, go_to_epilogue))


func _show_confrontation_answer(
	hud: InvestigationHud, record_ending: Callable, go_to_epilogue: Callable
) -> void:
	var page := _page("那张器材便笺",
		"林禾：「周四那张便笺，也是你特意从夹子里拿出来的？」\n\n"
		+ "周闻：「我知道你会赶过去。至于你真能翻到什么，我当时还不知道。周五何老师把单子一改，我才去拿的春册。」"
	)
	hud.show_evidence(page, false, "出示旧事故说明", _show_accident_answer.bind(hud, record_ending, go_to_epilogue),
		"返回上一段", _show_confrontation_opening.bind(hud, record_ending, go_to_epilogue))


func _show_accident_answer(
	hud: InvestigationHud, record_ending: Callable, go_to_epilogue: Callable
) -> void:
	var page := _page("旧事故说明",
		"周闻把旧说明的照片往自己这边拉，视线停在「未收到」三个字上。\n\n"
		+ "周闻：「维修的人说要封楼梯。楼上坐满了等孩子演出的家长，我叫他明早来。」\n"
		+ "何青：「当晚的说明只写了他离队，没写西梯照常使用是你定的。」\n"
		+ "周闻：「后来他们来问我，我把话说短了。短到只剩他自己走错。」"
	)
	var finished := InvestigationLog.has_entry(CONFRONTATION.id)
	hud.show_evidence(page, false, "回看留存记录" if finished else "留存原册",
		_finish_confrontation.bind(hud, record_ending, go_to_epilogue),
		"返回上一段", _show_confrontation_answer.bind(hud, record_ending, go_to_epilogue))


func _finish_confrontation(
	hud: InvestigationHud, record_ending: Callable, go_to_epilogue: Callable
) -> void:
	if _record(CONFRONTATION, record_ending):
		_show_retention_record(hud, record_ending, go_to_epilogue)


func _show_retention_record(
	hud: InvestigationHud, record_ending: Callable, go_to_epilogue: Callable
) -> void:
	hud.show_evidence(CONFRONTATION, false, "去雨棚", go_to_epilogue,
		"重读对质", _show_confrontation_opening.bind(hud, record_ending, go_to_epilogue))


func show_epilogue(hud: InvestigationHud, record_ending: Callable, go_to_front_desk: Callable) -> void:
	if InvestigationLog.has_entry(TESTIMONY.id):
		_show_signed_testimony(hud, record_ending, go_to_front_desk)
	else:
		_show_consent(hud, record_ending, go_to_front_desk)


func _show_consent(hud: InvestigationHud, record_ending: Callable, go_to_front_desk: Callable) -> void:
	var page := _page("20:05 · 雨棚",
		"雨已经小了。邵宁问过许南，他答应在雨棚多等几分钟。韩素擦干谱架袋，拆下印着旧地址的借还提示。\n\n"
		+ "何青：「我们找到了一份和西梯事故有关的记录。你愿意听听吗？」\n"
		+ "许南点了点头。林禾告诉他，中心在事故前已签收报修，旧说明里有一句写错了。"
	)
	hud.show_evidence(page, false, "听许南讲述", _show_testimony.bind(hud, record_ending, go_to_front_desk))


func _show_testimony(hud: InvestigationHud, record_ending: Callable, go_to_front_desk: Callable) -> void:
	if InvestigationLog.has_entry(TESTIMONY.id):
		_show_signed_testimony(hud, record_ending, go_to_front_desk)
		return
	var page := _page("许南回忆当晚", TESTIMONY.description
		+ "\n\n何青：「你愿意的话，把你记得的留一份。你先读一遍，签好自己带走一份。」")
	hud.show_evidence(page, false, "留存签字陈述", _finish_testimony.bind(hud, record_ending, go_to_front_desk),
		"返回上一段", _show_consent.bind(hud, record_ending, go_to_front_desk))


func _finish_testimony(hud: InvestigationHud, record_ending: Callable, go_to_front_desk: Callable) -> void:
	if _record(TESTIMONY, record_ending):
		_show_signed_testimony(hud, record_ending, go_to_front_desk)


func _show_signed_testimony(hud: InvestigationHud, record_ending: Callable, go_to_front_desk: Callable) -> void:
	hud.show_evidence(TESTIMONY, false, "去前台", go_to_front_desk,
		"重读雨棚对话", _show_consent.bind(hud, record_ending, go_to_front_desk))


func show_resolution(hud: InvestigationHud, record_ending: Callable) -> void:
	if InvestigationLog.has_entry(COMPLETE.id):
		hud.show_evidence(COMPLETE)
	elif InvestigationLog.has_entry(CORRECTION.id):
		_show_farewell(hud, record_ending)
	else:
		_show_notice(hud, record_ending)


func _show_notice(hud: InvestigationHud, record_ending: Callable) -> void:
	var page := _page("前台更正告示",
		"事故发生前，中心已收到西梯应急照明故障报告。原说明对应表述有误。"
		+ "相关原件已保留，疏散经过将根据现有材料和当事人陈述补充核实。\n\n"
		+ "何青准备在前台贴出更正告示，并留一份与原说明一起归档。"
	)
	hud.show_evidence(page, false, "贴出更正告示", _show_inventory_addendum.bind(hud, record_ending))


func _show_inventory_addendum(hud: InvestigationHud, record_ending: Callable) -> void:
	var page := _page("A01 清点单补记",
		"林禾打开周四那页清点单，在原来的「蓝布报修册一册」下另加一行。\n\n"
		+ "A01 原收秋季报修存根一册。蓝布封面，书脊下端白线三针。"
		+ "周六于 102 的 G03 旧谱架箱中取回，单独留存。"
	)
	hud.show_evidence(page, false, "共同签名并留档", _finish_correction.bind(hud, record_ending),
		"回看更正告示", _show_notice.bind(hud, record_ending))


func _finish_correction(hud: InvestigationHud, record_ending: Callable) -> void:
	if _record(CORRECTION, record_ending):
		_show_farewell(hud, record_ending)


func _show_farewell(hud: InvestigationHud, record_ending: Callable) -> void:
	var page := _page("谱架站稳了",
		"许南把归还回执折好，放进口袋。走到门槛时，他回头扶了一下晃动的谱架。"
		+ "韩素把一块折过的纸垫到白色的脚下，谱架站稳了。\n\n"
		+ "许南：「这次就放这儿吧。」"
	)
	page.preview = STEADY_STAND
	page.preview_scale = 2.4
	hud.show_evidence(page, false, "熄灯", _finish_ending.bind(hud, record_ending),
		"回看更正与补记", _show_correction_record.bind(hud, record_ending))


func _show_correction_record(hud: InvestigationHud, record_ending: Callable) -> void:
	hud.show_evidence(CORRECTION, false, "返回", _show_farewell.bind(hud, record_ending))


func _finish_ending(hud: InvestigationHud, record_ending: Callable) -> void:
	if _record(COMPLETE, record_ending):
		hud.show_evidence(COMPLETE)


func _record(entry: EvidenceEntry, record_ending: Callable) -> bool:
	if not InvestigationLog.has_entry(entry.id):
		record_ending.call(entry)
	return InvestigationLog.has_entry(entry.id)


func _page(title: String, description: String) -> EvidenceEntry:
	var entry := EvidenceEntry.new()
	entry.title = title
	entry.description = description
	return entry
