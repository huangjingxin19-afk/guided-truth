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
	await _play_back_yard_route(false)
	await _restart()
	await _interact_at(Vector2(350, 360), "领取委托")
	_close()
	await _interact_at(Vector2(793, 344), "前往走廊")
	await _room_ready("Corridor")
	await _play_back_yard_route(true)
	await _restart()
	_check(not _chapter.can_enter_supply_door(), "Restart clears the back-door authorization.")
	_check(_chapter.reenactment_stage == _chapter.ReenactmentStage.FIRST_PASS, "Restart resets the installed pad and reenactment stage.")
	await _check_touchscreen_movement()
	print("Chapter one route failures: ", _failures)
	quit(int(_failures > 0))


func _check_touchscreen_movement() -> void:
	# Use Godot's built-in touch emulation to enter the same mode as the Android HUD.
	Input.emulate_touch_from_mouse = true
	_transition.start_new_game()
	await _room_ready("FrontDesk")
	var joystick := _hud.get_node("TouchJoystick") as Control
	_check(joystick.visible and _room.get_node("WalkHint").text == "拖动左下角摇杆移动", "Touchscreen mode shows the joystick and its movement hint.")
	var start := _player.global_position
	var floor_point := Vector2(475, 415)
	_tap(floor_point)
	await _settle()
	_check(_player.global_position.is_equal_approx(start), "A free touch on walkable ground cannot move the player.")
	_click(floor_point)
	await _settle()
	_check(_player.global_position.is_equal_approx(start), "A mouse event on walkable ground cannot bypass touchscreen movement.")

	var center := joystick.get_global_transform_with_canvas() * (joystick.size * 0.5)
	_send_touch(center, true)
	var drag := InputEventScreenDrag.new()
	drag.position = center + Vector2(30, -15)
	root.push_input(drag, true)
	for frame in range(90):
		await physics_frame
		if _hud.interaction_button.visible:
			break
	_send_touch(drag.position, false)
	await _settle()
	_check(_player.global_position.distance_to(start) > 20.0 and _player.velocity.is_zero_approx(), "Dragging the joystick moves the player and releasing it stops movement.")
	_check(_hud.interaction_button.visible and _hud.interaction_button.text == "领取委托", "Approaching with the joystick still offers the touchscreen action.")
	_tap_button(_hud.interaction_button)
	await _settle()
	_check(_hud.header.text == "102 调查委托" and _hud.is_open(), "Tapping the touchscreen action still opens evidence.")
	_close()
	await _settle()
	_tap(Vector2(350, 225))
	await _settle()
	_check(_hud.header.text == "102 调查委托" and _hud.is_open(), "Touch still works on a reachable scene interaction point.")
	_close()
	await _settle()
	await _reread("102 调查委托", "何青")


func _play_back_yard_route(backtrack: bool) -> void:
	await _enter_back_yard()
	_check(_player.position.is_equal_approx(Vector2(227, 372)), "Arrive in the yard at the outer passage.")
	await _capture("06-back-yard")
	await _interact_at(Vector2(730, 346), "检查器材门")
	_check(current_scene == _room and _room.get_node("WalkHint").text == "先去推车旁找韩素", "The closed supply door points to Han Su.")

	if not backtrack:
		await _inspect_cart_sheet()
		_check(not _chapter.can_enter_supply_door(), "The cart sheet alone does not grant entry.")
	await _interact_at(Vector2(390, 367), "查看后门授权")
	_check(_hud.header.text == "后门授权" and _hud.description.text.contains("有效至周四晚。签字：何青"), "Han Su shows the signed authorization and grants entry.")
	await _check_card("back-door authorization")
	await _capture("08-back-door-authorization")
	_close()
	await _reread("后门授权", "何青")
	await _interact_at(Vector2(390, 367), "查看后门授权")
	_check(_log.entries().size() == (3 if backtrack else 5), "Seeing the authorization again does not duplicate evidence.")
	_close()
	await _enter_102()
	_check(_player.position.is_equal_approx(Vector2(550, 280)), "Enter 102 on the inside of the supply door.")
	_check(_room.get_node("Scenery/FootPad").visible, "The pad starts on the floor in a new game.")
	await _interact_at(Vector2(580, 290), "查看地面轮痕")
	_check(_hud.header.text.contains("轮痕"), "The wheel tracks can be investigated from the new entrance.")
	_close()
	await _interact_at(Vector2(722, 286), "看推车过门槛")
	await _finish_presentation("第一次过门槛")
	await _interact_at(Vector2(503, 280), "查看橡胶凳脚垫")
	_check(_hud.evidence_action_button.text == "装回脚垫", "The pad can be installed after the first pass.")
	_tap_button(_hud.evidence_action_button)
	await _finish_presentation("装回脚垫")
	_check(not _room.get_node("Scenery/FootPad").visible, "Installation removes the pad from the floor.")

	if backtrack:
		_check(not _log.has_entry(_chapter.SEAL.id) and not _log.has_entry(_chapter.CART_SHEET.id), "The seal and the cart sheet can be left for later.")
		await _return_to_yard()
		await _interact_at(Vector2(158, 346), "经外廊回走廊")
		await _room_ready("Corridor")
		_check(_player.position.is_equal_approx(Vector2(783, 378)), "Return near the corridor's outer passage.")
		await _interact_at(Vector2(610, 352), "查看102 正门封条")
		_check(_hud.header.text == "102 正门封条", "The seal can still be registered after installing the pad.")
		_close()
		await _enter_back_yard()
		await _enter_102()
		_check(not _room.get_node("Scenery/FootPad").visible, "The installed pad stays off the floor after a round trip.")
		_check(not _room.get_node("Investigation/FootPadPoint").visible, "The installed pad no longer has a floor interaction.")

	await _capture("09-room102-ready-for-second-pass")
	await _interact_at(Vector2(722, 286), "再推一次")
	await _finish_presentation("第二次过门槛")
	_check(_log.has_entry(_chapter.REENACTMENT.id), "The second pass records the comparison.")
	await _reread("推车复走", "前后轮照样磕过门槛")

	await _return_to_yard()
	if backtrack:
		_check(_room.get_node("ChapterStatus").text.contains("随车单"), "A missing cart sheet is called out after completing the reenactment.")
		await _inspect_cart_sheet()
	await _reread("随车单", "折叠凳六把")
	await _enter_102()
	_check(not _room.get_node("Investigation/HanSuPoint").visible, "Completion survives a round trip without reopening either replay.")
	_check(_room.get_node("ChapterStatus").text.contains("取用记录与推车复走已核对"), "The completed route is acknowledged after all evidence is collected.")
	_check(_log.entries().size() == 8 and _chapter.story_time() == "周四 18:40", "A completed route retains all eight records and the scene time.")


func _enter_back_yard() -> void:
	await _interact_at(Vector2(783, 344), "经外廊去后院")
	await _room_ready("BackYard")


func _enter_102() -> void:
	await _interact_at(Vector2(730, 346), "从器材门进 102")
	await _room_ready("Room102")


func _return_to_yard() -> void:
	await _interact_at(Vector2(483, 257), "返回后院")
	await _room_ready("BackYard")
	_check(_player.position.is_equal_approx(Vector2(730, 373)), "Return to the outside of the supply door.")


func _inspect_cart_sheet() -> void:
	await _interact_at(Vector2(532, 372), "查看随车单")
	_check(_hud.header.text == "随车单" and _hud.description.text.contains("韩素，折叠凳六把，领回活动室"), "The cart sheet records the holder, quantity and destination.")
	await _check_card("cart sheet")
	await _capture("07-cart-sheet")
	_close()


func _interact_at(position: Vector2, action: String) -> void:
	await _walk_to(position)
	if not _hud.interaction_button.visible or not _hud.interaction_button.text.ends_with(action):
		_check(false, "Expected nearby action: %s. Found: %s" % [action, _hud.interaction_button.text])
		quit(1)
		return
	_tap_button(_hud.interaction_button)
	await _settle()


func _finish_presentation(title: String) -> void:
	await _settle()
	_check(_hud.is_open() and _hud.header.text == title and not _hud.close_button.visible, "Started presentation: " + title)
	var animation := _hud.presentation_slot.get_node("ThresholdReenactment/AnimationPlayer") as AnimationPlayer
	animation.advance(3.5)
	await _settle()
	_check(not _hud.is_open(), "Presentation finished: " + title)


func _restart() -> void:
	# Exercise the actual restart UI, including cancel before confirming.
	var recorded: int = _log.entries().size()
	_tap_button(_hud.get_node("NotebookButton"))
	await _settle()
	var restart := _notebook_button("重新开始")
	await _settle()
	_tap_button(restart)
	await _settle()
	_check(_log.entries().size() == recorded, "The restart confirmation does not clear progress prematurely.")
	_close()
	await _settle()
	_tap_button(_hud.get_node("NotebookButton"))
	await _settle()
	restart = _notebook_button("重新开始")
	await _settle()
	_tap_button(restart)
	await _settle()
	_tap_button(_hud.evidence_action_button)
	await _room_ready("FrontDesk")
	_check(_log.entries().is_empty() and not _chapter.commission_accepted and not _chapter.corridor_visited, "Restart clears every note and first-chapter flag.")
	_check(_player.position.is_equal_approx(Vector2(230, 420)), "Restart uses the starting entrance.")
	_check(_chapter.story_time() == "周四 18:35", "Restart resets story time.")


func _room_ready(expected: String) -> void:
	await _settle()
	_room = current_scene
	_check(_room != null and _room.name == expected, "Expected room: " + expected)
	_hud = _room.get_node("InvestigationHud")
	_player = _room.get_node("WalkableFloor/DepthSort/LinHe")
	await _settle()


func _walk_to(destination: Vector2) -> void:
	_click(destination)
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
		await _settle()
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
			_hud.notebook.ensure_control_visible(button)
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
		_send_touch(point, pressed)


func _send_touch(point: Vector2, pressed: bool) -> void:
	var touch := InputEventScreenTouch.new()
	touch.position = point
	touch.pressed = pressed
	root.push_input(touch, true)


func _click(point: Vector2) -> void:
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = point
		click.pressed = pressed
		root.push_input(click, true)


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
