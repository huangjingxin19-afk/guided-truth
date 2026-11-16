extends VBoxContainer

const EvidenceEntry = preload("res://investigation/evidence_entry.gd")

signal entry_selected(entry: EvidenceEntry)


func setup(
	entries: Array[EvidenceEntry], preview_style: StyleBox, action_label: String, action: Callable,
	excerpts: Array[String] = []
) -> void:
	var views := HBoxContainer.new()
	views.add_theme_constant_override("separation", 16)
	add_child(views)
	for index in entries.size():
		var entry := entries[index]
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 10)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		views.add_child(column)

		var panel := Panel.new()
		panel.custom_minimum_size = Vector2(252, 124)
		panel.clip_contents = true
		panel.add_theme_stylebox_override("panel", preview_style)
		column.add_child(panel)

		var center := Control.new()
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(center)
		center.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		var preview := entry.preview.instantiate() as Node2D
		preview.scale = Vector2.ONE * entry.preview_scale * 0.62
		center.add_child(preview)

		if index < excerpts.size() and not excerpts[index].is_empty():
			var excerpt := Label.new()
			excerpt.text = excerpts[index]
			excerpt.custom_minimum_size = Vector2(252, 64)
			excerpt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			excerpt.vertical_alignment = VERTICAL_ALIGNMENT_TOP
			excerpt.add_theme_font_size_override("font_size", 16)
			column.add_child(excerpt)

		var enlarge := Button.new()
		enlarge.text = "放大" + entry.title
		enlarge.custom_minimum_size.y = 48
		enlarge.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		enlarge.pressed.connect(entry_selected.emit.bind(entry))
		column.add_child(enlarge)

	if action.is_valid():
		var submit := Button.new()
		submit.text = action_label
		submit.custom_minimum_size.y = 48
		submit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		submit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		submit.pressed.connect(action)
		add_child(submit)
