extends VBoxContainer

signal submitted(first_answer: int, second_answer: int)

@export var first_question: String
@export var second_question: String
@export var second_choice_preview: PackedScene

var _first_group := ButtonGroup.new()
var _second_group := ButtonGroup.new()
var _submit: Button
var _feedback: Label


func setup(first_choices: Array, second_choices: Array) -> void:
	add_theme_constant_override("separation", 10)
	var questions := HBoxContainer.new()
	questions.add_theme_constant_override("separation", 16)
	add_child(questions)
	_add_question(questions, first_question, first_choices, _first_group)
	_add_question(questions, second_question, second_choices, _second_group, second_choice_preview)

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


func _add_question(
	parent: HBoxContainer, title: String, choices: Array, group: ButtonGroup, preview: PackedScene = null
) -> void:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	parent.add_child(column)
	var question := Label.new()
	question.text = title
	question.add_theme_font_size_override("font_size", 20)
	column.add_child(question)
	var options: BoxContainer = column
	if preview != null:
		var panel := Control.new()
		panel.custom_minimum_size = Vector2(300, 106)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(panel)
		var illustration := preview.instantiate() as Node2D
		illustration.position = panel.custom_minimum_size * 0.5
		illustration.scale = Vector2.ONE * 0.92
		panel.add_child(illustration)
		options = HBoxContainer.new()
		options.add_theme_constant_override("separation", 4)
		column.add_child(options)
	for index in choices.size():
		var button := Button.new()
		button.text = choices[index]
		button.set_meta(&"answer", index)
		button.toggle_mode = true
		button.button_group = group
		button.custom_minimum_size.y = 52
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 18)
		button.add_theme_color_override("font_pressed_color", Color(1.0, 0.8, 0.46))
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(_update_submit)
		options.add_child(button)


func _update_submit() -> void:
	_submit.disabled = _first_group.get_pressed_button() == null or _second_group.get_pressed_button() == null


func _submit_choices() -> void:
	submitted.emit(
		_first_group.get_pressed_button().get_meta(&"answer"),
		_second_group.get_pressed_button().get_meta(&"answer")
	)


func clear_feedback() -> void:
	_feedback.text = "各选一项。需要补查时可关闭此页，打开笔记。"


func show_feedback(message: String) -> void:
	_feedback.text = message
