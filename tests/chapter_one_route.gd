extends SceneTree
## End-to-end first-chapter route through real movement and HUD input.

var _failures := 0
var _room: Node
var _hud: CanvasLayer
var _player: CharacterBody2D
var _log: Node
var _chapter: Node
var _transition: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_log = root.get_node("InvestigationLog")
	_chapter = root.get_node("ChapterOne")
	_transition = root.get_node("RoomTransition")
	_transition.start_new_game()
	await _room_ready("FrontDesk")
	_check(_log.entries().is_empty() and not _chapter.commission_accepted, "New game starts with an empty log and no commission.")
	_check(_room.get_node("Investigation/CorridorExit").disabled, "Receive the commission before leaving the front desk.")
	_tap(Vector2(350, 225))
	await _settle()
	_check(not _hud.is_open() and _log.entries().is_empty(), "A distant tap cannot accept the commission.")
	await _walk_to(Vector2(350, 360))
	_check(_hud.interaction_button.text.ends_with("领取委托"), "Approaching He Qing offers the shared interaction button.")
	await _capture("01-front-desk")
	_tap_button(_hud.interaction_button)
	await _settle()
	_check(_chapter.commission_accepted and _log.entries().size() == 2, "Accepting records both the commission and Zhou Wen's note.")
	_check(_hud.header.text == "102 调查委托", "The commission opens on acceptance.")
	_check(not _hud.interaction_button.visible and _player.velocity.is_zero_approx(), "Reading stops walking and hides the interaction prompt.")
	_check(_hud.description.text.contains("核实 102 傍晚的出入者、路线和声响来源"), "Commission matches the final script.")
	await _check_card("commission")
	await _capture("02-commission")
	_tap_button(_hud.evidence_action_button)
	await _settle()
	_check(_hud.header.text == "器材交接便笺" and _hud.description.text.contains("领取人和件数见随车单"), "The note unfolds with its complete routing text.")
	await _check_card("equipment note")
	await _capture("03-equipment-note")
	_close()
	await _settle()
	_press_e()
	await _settle()
	_check(_log.entries().size() == 2 and _hud.is_open(), "E can reread the commission without duplicate entries.")
	_close()
	await _walk_to(Vector2(793, 344))
	_check(_hud.interaction_button.text.ends_with("前往走廊"), "The exit uses the shared interaction button.")
	_tap_button(_hud.interaction_button)
	await _room_ready("Corridor")
	_check(_player.position.is_equal_approx(Vector2(230, 374)), "Arrive at the corridor's named entrance.")
	_check(_chapter.story_time() == "周四 18:40", "First corridor visit advances story time.")
	await _reread("102 调查委托", "核实 102 傍晚的出入者、路线和声响来源")
	await _reread("器材交接便笺", "周四 18:40 后院，器材取用。领取人和件数见随车单")
	_tap(Vector2(632, 260))
	await _settle()
	_check(not _hud.is_open() and _log.entries().size() == 2, "A distant tap cannot register the seal.")
	await _walk_to(Vector2(610, 352))
	_check(_hud.interaction_button.text.ends_with("查看102 正门封条"), "Approaching the sealed door offers inspection, not entry.")
	await _capture("04-corridor")
	_press_e()
	await _settle()
	_check(_hud.header.text == "102 正门封条" and _log.entries().size() == 3, "E inspects and registers the intact seal.")
	_check(_hud.preview_container.visible and _hud.description.text.contains("连续跨贴门扇和门框"), "Seal evidence includes the intact cross-seam preview and description.")
	await _check_card("seal")
	await _capture("05-seal")
	_close()
	await _settle()
	_tap_button(_hud.interaction_button)
	await _settle()
	_check(_log.entries().size() == 3, "Repeated seal inspection is idempotent.")
	_close()
	await _walk_to(Vector2(161, 344))
	_tap_button(_hud.interaction_button)
	await _room_ready("FrontDesk")
	_check(_player.position.is_equal_approx(Vector2(755, 374)), "Return at the front desk's corridor entrance.")
	_check(_chapter.story_time() == "周四 18:40", "Backtracking does not rewind story time.")
	await _reread("102 调查委托", "何青")
	await _reread("器材交接便笺", "周闻")
	await _reread("102 正门封条", "边缘没有揭起")
	await _walk_to(Vector2(350, 360))
	_tap_button(_hud.interaction_button)
	await _settle()
	_check(_log.entries().size() == 3, "Revisiting He Qing preserves all three notes without duplicates.")
	_close()
	await _walk_to(Vector2(793, 344))
	_press_e()
	await _room_ready("Corridor")
	_check(_room.get_node("ChapterStatus").text.contains("封条已登记"), "Seal progress remains after another room change.")
	# Exercise the actual restart UI, including cancel before confirming.
	_tap_button(_hud.get_node("NotebookButton"))
	await _settle()
	_tap_button(_notebook_button("重新开始"))
	await _settle()
	_check(_log.entries().size() == 3, "The restart confirmation does not clear progress prematurely.")
	_close()
	await _settle()
	_tap_button(_hud.get_node("NotebookButton"))
	await _settle()
	_tap_button(_notebook_button("重新开始"))
	await _settle()
	_tap_button(_hud.evidence_action_button)
	await _room_ready("FrontDesk")
	_check(_log.entries().is_empty() and not _chapter.commission_accepted and not _chapter.corridor_visited, "Restart clears every note and first-chapter flag.")
	_check(_player.position.is_equal_approx(Vector2(230, 420)), "Restart uses the starting entrance.")
	_check(_chapter.story_time() == "周四 18:35", "Restart resets story time.")
	print("Chapter one route failures: ", _failures)
	quit(int(_failures > 0))


func _room_ready(expected: String) -> void:
	await _settle()
	_room = current_scene
	_check(_room != null and _room.name == expected, "Expected room: " + expected)
	_hud = _room.get_node("InvestigationHud")
	_player = _room.get_node("WalkableFloor/DepthSort/LinHe")
	await _settle()


func _walk_to(destination: Vector2) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = destination
	click.pressed = true
	root.push_input(click, true)
	click = click.duplicate()
	click.pressed = false
	root.push_input(click, true)
	for frame in range(480):
		await physics_frame
		if _player.global_position.distance_to(destination) < 3.0:
			break
	_check(_player.global_position.distance_to(destination) < 3.0, "Walkable route reaches %s (actual %s)." % [destination, _player.global_position])
	await _settle()


func _reread(title: String, expected: String) -> void:
	_tap_button(_hud.get_node("NotebookButton"))
	await _settle()
	var button := _notebook_button(title)
	_check(button != null, "Notebook contains " + title)
	if button != null:
		_tap_button(button)
		await _settle()
		_check(_hud.header.text == title and _hud.description.text.contains(expected), "Notebook rereads " + title)
		_check(not _hud.evidence_action_button.visible, "Notebook entries remain read-only.")
		_close()
		await _settle()
	_close()
	await _settle()


func _notebook_button(title: String) -> Button:
	for button in _hud.notebook_list.get_children():
		if button is Button and button.text == title:
			return button
	return null


func _check_card(context: String) -> void:
	await _settle()
	var card := _hud.get_node("Overlay/Card") as Control
	var rect := card.get_global_rect()
	_check(root.get_visible_rect().encloses(rect), "Evidence fits in the viewport: " + context)


func _capture(label: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../.test-runtime/" + label + ".png")


func _close() -> void:
	_tap_button(_hud.close_button)


func _tap_button(button: Control) -> void:
	if button == null:
		_check(false, "Requested button exists.")
		return
	_tap(button.get_global_transform_with_canvas() * (button.size * 0.5))


func _tap(point: Vector2) -> void:
	for pressed in [true, false]:
		var touch := InputEventScreenTouch.new()
		touch.position = point
		touch.pressed = pressed
		root.push_input(touch, true)


func _press_e() -> void:
	for pressed in [true, false]:
		var key := InputEventKey.new()
		key.physical_keycode = KEY_E
		key.pressed = pressed
		root.push_input(key, true)


func _settle() -> void:
	await physics_frame
	await physics_frame
	await process_frame


func _check(passed: bool, context: String) -> void:
	if not passed:
		_failures += 1
		push_error(context)
