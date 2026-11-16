extends Control
## Presentation-only view for the final causal reasoning interaction.
## Data and correctness remain owned by the room/chapter controller.

signal request_group(group: int)
signal submit_group(group: int, change: int, proof: int)
signal request_entry(key: StringName)
signal submit_motive(item: int, claim: int)
signal hint_requested(group: int)
signal request_motive

const BUTTON_HEIGHT := 48.0

var _root: VBoxContainer
var _status: Label
var _scroll: ScrollContainer
var _body: VBoxContainer
var _footer: HBoxContainer
var _group_id := -1
var _change_id := -1
var _proof_id := -1
var _item_id := -1
var _claim_id := -1


func _ready() -> void:
	custom_minimum_size = Vector2(540, 282)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root = VBoxContainer.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_theme_constant_override("separation", 10)
	add_child(_root)
	_status = Label.new()
	_status.name = "StatusLabel"
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size.y = 34
	_root.add_child(_status)
	_scroll = ScrollContainer.new()
	_scroll.name = "ReasoningScroll"
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_root.add_child(_scroll)
	_body = VBoxContainer.new()
	_body.name = "Body"
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 8)
	_scroll.add_child(_body)
	_footer = HBoxContainer.new()
	_footer.name = "Footer"
	_footer.alignment = BoxContainer.ALIGNMENT_CENTER
	_footer.add_theme_constant_override("separation", 10)
	_root.add_child(_footer)


func show_group_menu(groups: Array[Dictionary]) -> void:
	_clear()
	var completed_count := 0
	for entry in groups:
		if bool(entry.get("completed", false)):
			completed_count += 1
	_status.text = "进度：%d/3　选择一组因果关系开始或回看。" % completed_count
	for entry in groups:
		var id := int(entry.get("id", -1))
		var caption := str(entry.get("title", "第%d组" % (id + 1)))
		if bool(entry.get("completed", false)):
			caption += "　✓ 已完成 · 回看"
		var button := _make_button("Group%dButton" % (id + 1), caption)
		button.pressed.connect(request_group.emit.bind(id))
		_body.add_child(button)
	var all_done := groups.size() >= 3
	for entry in groups:
		all_done = all_done and bool(entry.get("completed", false))
	if all_done:
		_add_footer_action("MotiveButton", "回答最后问题", request_motive.emit)


func show_group(
	group: int,
	title: String,
	changes: Array[String],
	proofs: Array[Dictionary],
	available_proofs: Array[StringName]
) -> void:
	_clear()
	_group_id = group
	_change_id = -1
	_proof_id = -1
	_status.text = title + "\n先选实际变化，再选一组证据。"
	_add_section_label("实际变化")
	for index in changes.size():
		var button := _make_button("ChangeButton%d" % index, changes[index])
		button.pressed.connect(_select_change.bind(index))
		_body.add_child(button)
	_add_section_label("证据组合（选择一项）")
	for index in proofs.size():
		var proof: Dictionary = proofs[index]
		var key := StringName(proof.get("key", &""))
		var unlocked := available_proofs.has(key)
		var caption := str(proof.get("title", "证据")) if unlocked else "尚未取得的记录"
		var row := HBoxContainer.new()
		row.name = "ProofRow%d" % index
		row.add_theme_constant_override("separation", 8)
		var button := _make_button("ProofButton%d" % index, caption)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = not unlocked
		button.pressed.connect(_select_proof.bind(index))
		row.add_child(button)
		if unlocked:
			var inspect := _make_button("InspectButton%d" % index, "回看")
			inspect.custom_minimum_size.x = 92
			inspect.pressed.connect(request_entry.emit.bind(key))
			row.add_child(inspect)
		_body.add_child(row)
	if available_proofs.size() < proofs.size():
		_add_note("有些记录尚未取得；取得后再回来组合。")
	_add_footer_action("HintButton", "提示", hint_requested.emit.bind(group))
	_add_footer_action("SubmitButton", "确认推理", _submit_group)
	_add_footer_action("BackButton", "返回分组", request_group.emit.bind(-1))


func show_feedback(text: String, allow_retry := true, preserve_selection := false) -> void:
	if preserve_selection:
		_status.text = text
		return
	_clear()
	_change_id = -1
	_proof_id = -1
	_status.text = text
	if allow_retry:
		_add_footer_action("RetryGroupButton", "重试本组", request_group.emit.bind(_group_id))
	_add_footer_action("GroupMenuButton", "返回分组", request_group.emit.bind(-1))


func show_motive(items: Array[String], claims: Array[String]) -> void:
	_clear()
	_item_id = -1
	_claim_id = -1
	_status.text = "最后的问题：带走了哪件物品？旧说明中的哪句话不对？"
	_add_section_label("带走的物品")
	for index in items.size():
		var button := _make_button("ItemOption%d" % index, items[index])
		button.pressed.connect(_select_item.bind(index))
		_body.add_child(button)
	_add_section_label("旧说明中的错误说法")
	for index in claims.size():
		var button := _make_button("ClaimOption%d" % index, claims[index])
		button.pressed.connect(_select_claim.bind(index))
		_body.add_child(button)
	_add_footer_action("MotiveSubmitButton", "提交答案", _submit_motive)
	_add_footer_action("MotiveBackButton", "返回分组/结果", request_group.emit.bind(-1))


func _submit_group() -> void:
	if _change_id >= 0 and _proof_id >= 0:
		submit_group.emit(_group_id, _change_id, _proof_id)
	else:
		_status.text = "请先选择实际变化和一项已取得的证据组合。"


func _submit_motive() -> void:
	if _item_id >= 0 and _claim_id >= 0:
		submit_motive.emit(_item_id, _claim_id)
	else:
		_status.text = "请回答两个问题后再提交。"


func _select_change(index: int) -> void:
	_change_id = index
	_mark_selected("ChangeButton", index)


func _select_proof(index: int) -> void:
	_proof_id = index
	_mark_selected("ProofButton", index)


func _select_item(index: int) -> void:
	_item_id = index
	_mark_selected("ItemOption", index)


func _select_claim(index: int) -> void:
	_claim_id = index
	_mark_selected("ClaimOption", index)


func _mark_selected(prefix: String, index: int) -> void:
	for button in _body.find_children(prefix + "*", "Button", true, false):
		button.button_pressed = false
		button.toggle_mode = true
	for button in _body.find_children(prefix + "*", "Button", true, false):
		if button.name == prefix + str(index):
			button.button_pressed = true


func _clear() -> void:
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	for child in _footer.get_children():
		_footer.remove_child(child)
		child.queue_free()


func _make_button(node_name: String, caption: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = caption
	button.custom_minimum_size.y = BUTTON_HEIGHT
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.focus_mode = Control.FOCUS_ALL
	return button


func _add_section_label(caption: String) -> void:
	var label := Label.new()
	label.text = caption
	label.add_theme_font_size_override("font_size", 20)
	_body.add_child(label)


func _add_note(caption: String) -> void:
	var label := Label.new()
	label.text = caption
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_child(label)


func _add_footer_action(node_name: String, caption: String, action: Callable) -> void:
	var button := _make_button(node_name, caption)
	button.custom_minimum_size.x = 120
	button.pressed.connect(action)
	_footer.add_child(button)
