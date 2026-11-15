extends VBoxContainer

signal submitted(route: int, sound: int)

var _route := ButtonGroup.new()
var _sound := ButtonGroup.new()
var _submit: Button
var _feedback: Label


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	var questions := HBoxContainer.new()
	questions.add_theme_constant_override("separation", 16)
	add_child(questions)
	_add_question(questions, "谁从哪扇门运了什么？", ChapterOne.ROUTE_CHOICES, _route)
	_add_question(questions, "拖响是怎么来的？", ChapterOne.SOUND_CHOICES, _sound)

	_feedback = Label.new()
	_feedback.custom_minimum_size = Vector2(528, 28)
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.add_theme_font_size_override("font_size", 19)
	add_child(_feedback)

	_submit = Button.new()
	_submit.name = "Submit"
	_submit.text = "提交结论"
	_submit.custom_minimum_size.y = 48
	_submit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_submit.disabled = true
	_submit.pressed.connect(_submit_choices)
	add_child(_submit)
	clear_feedback()


func _add_question(parent: HBoxContainer, title: String, choices: Array, group: ButtonGroup) -> void:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	parent.add_child(column)
	var question := Label.new()
	question.text = title
	question.add_theme_font_size_override("font_size", 20)
	column.add_child(question)
	for index in choices.size():
		var button := Button.new()
		button.text = choices[index]
		button.set_meta(&"answer", index)
		button.toggle_mode = true
		button.button_group = group
		button.custom_minimum_size.y = 52
		button.add_theme_font_size_override("font_size", 18)
		button.add_theme_color_override("font_pressed_color", Color(1.0, 0.8, 0.46))
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(_update_submit)
		column.add_child(button)


func _update_submit() -> void:
	_submit.disabled = _route.get_pressed_button() == null or _sound.get_pressed_button() == null


func _submit_choices() -> void:
	submitted.emit(
		_route.get_pressed_button().get_meta(&"answer"),
		_sound.get_pressed_button().get_meta(&"answer")
	)


func clear_feedback() -> void:
	_feedback.text = "各选一项。需要补查时可关闭此页，打开笔记。"


func show_feedback(message: String) -> void:
	_feedback.text = "何青：" + message
