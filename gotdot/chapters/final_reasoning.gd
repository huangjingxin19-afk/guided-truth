extends RefCounted
## Evidence and validation for the three independent conclusions at the long desk.

const EvidenceEntry = preload("res://investigation/evidence_entry.gd")
const MOTIVE = preload("res://investigation/final_motive.tres")
const FINDINGS: Array[EvidenceEntry] = [
	preload("res://investigation/final_cause_inventory.tres"),
	preload("res://investigation/final_cause_handover.tres"),
	preload("res://investigation/final_cause_receipt.tres"),
]
const CASES := [
	{
		"title": "韩素从后门取凳",
		"changes": ["何青改在 102 开箱复核。", "白线秋册从抽屉取出，登记进 A01。", "取凳后，A01 被送到了办公室。"],
		"answer": 1,
		"proof": 0,
		"hint": "交接清单里多了哪一样？",
	},
	{
		"title": "访客页由邵宁收存",
		"changes": ["资料留在 102 开箱复核，周闻在场分类。", "A01 仍按原定计划送到办公室。", "当晚的后院签收改由周闻经手。"],
		"answer": 0,
		"proof": 2,
		"hint": "搬到办公室和留在 102，谁能碰到资料？",
	},
	{
		"title": "许南在雨棚还谱架",
		"changes": ["许南进了 102，在长桌边办完签收。", "韩素留在 102 照看 A01。", "林禾和韩素去雨棚签收，周闻留在 102。"],
		"answer": 2,
		"proof": 1,
		"hint": "签收的两分钟里，哪道门有人守着，谁留在里面？",
	},
]
const PROOFS := [
	{
		"key": &"inventory",
		"title": "器材交接便笺、首次清点单",
		"required": [&"chapter1_equipment_note", &"a01_signed_inventory"],
	},
	{
		"key": &"receipt",
		"title": "离场签收、两门查证和 G03",
		"required": [
			&"shelter_return_notice", &"shelter_duty_board", &"shelter_102_departure",
			&"shelter_signed_receipt", &"final_han_su_testimony", &"final_seal_confirmation",
			&"final_g03_card", &"final_autumn_ledger",
		],
	},
	{
		"key": &"handover",
		"title": "改签公告、A01 对照和春册去向",
		"required": [&"handover_notice", &"final_review_discrepancy"],
		"alternatives": [&"spring_ledger_pickup", &"final_shao_ning_testimony"],
	},
]
const MOTIVE_ITEMS: Array[String] = ["周四访客登记页", "白线秋季报修存根", "杯圈春季报修存根"]


static func completed_count(ids: Dictionary) -> int:
	var count := 0
	for finding in FINDINGS:
		if ids.has(finding.id):
			count += 1
	return count


static func proof_is_available(proof: Dictionary, ids: Dictionary) -> bool:
	for id: StringName in proof.required:
		if not ids.has(id):
			return false
	var alternatives: Array = proof.get("alternatives", [])
	return alternatives.is_empty() or alternatives.any(func(id: StringName) -> bool: return ids.has(id))


static func missing_proof_hint(group: int, ids: Dictionary) -> String:
	if group == 1 and not ids.has(&"spring_ledger_pickup") and not ids.has(&"final_shao_ning_testimony"):
		return "到前台向邵宁核对带杯圈的春册是谁取走的。"
	if group == 2:
		if not ids.has(&"final_han_su_testimony"):
			return "向 102 的韩素核对离场与器材门的情况。"
		if not ids.has(&"final_seal_confirmation"):
			return "向 102 的何青核对正门封条。"
	return "从笔记回看本案记录，再检查缺少的证据。"


static func validate_group(group: int, change: int, proof: int, ids: Dictionary) -> String:
	if group < 0 or group >= CASES.size():
		return "请先选择一案。"
	var choice: Dictionary = CASES[group]
	if change != choice.answer:
		return "实际变化还对不上。" + choice.hint
	if not proof_is_available(PROOFS[choice.proof], ids):
		return missing_proof_hint(group, ids)
	if proof != choice.proof:
		return "这组记录还不能把调查后的变化和周闻的行动连起来。"
	return ""


static func checkpoint_is_valid(ids: Dictionary) -> bool:
	for group in FINDINGS.size():
		if ids.has(FINDINGS[group].id) and (
			not ids.has(&"final_a047_finding") or not proof_is_available(PROOFS[CASES[group].proof], ids)
		):
			return false
	return not ids.has(MOTIVE.id) or completed_count(ids) == FINDINGS.size()
