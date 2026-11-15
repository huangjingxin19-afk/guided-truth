extends SceneTree
## End-to-end first chapter and second-chapter opening through real HUD input.

var _failures := 0
var _room: Node
var _hud: CanvasLayer
var _player: CharacterBody2D
var _log: Node
var _chapter: Node
var _chapter_two: Node
var _transition: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_log = root.get_node("InvestigationLog")
	_chapter = root.get_node("ChapterOne")
	_chapter_two = root.get_node("ChapterTwo")
	_transition = root.get_node("RoomTransition")
	_transition.start_new_game()
	await _room_ready("FrontDesk")
	_check(_log.entries().is_empty() and not _chapter.commission_accepted, "New game starts with an empty log and no commission.")
	_check(_room.get_node("Investigation/CorridorExit").disabled, "Receive the commission before leaving the front desk.")
	_check(not _room.get_node("Investigation/PhotoPoint").visible and not _chapter_two.can_start(), "Friday clues stay hidden before the chapter handoff.")
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
	_check(_chapter.case_stage == _chapter.CaseStage.DEDUCTION, "Restart resets the conclusion and inventory stages.")
	await _check_touchscreen_movement()
	print("Chapter route failures: ", _failures)
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
	_check(not _room.get_node("Investigation/ReasoningPoint").visible and not _room.get_node("Investigation/DrawerPoint").visible, "Reasoning and inventory are gated before reenactment.")
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
	_check(_room.get_node("Investigation/ReasoningPoint").visible == (not backtrack), "Reasoning opens after the two passes only when the required evidence is present.")
	await _reread("推车复走", "前后轮照样磕过门槛")

	await _return_to_yard()
	if backtrack:
		_check(_room.get_node("ChapterStatus").text.contains("随车单"), "A missing cart sheet is called out after completing the reenactment.")
		await _inspect_cart_sheet()
	await _reread("随车单", "折叠凳六把")
	await _enter_102()
	_check(not _room.get_node("Investigation/HanSuPoint").visible, "Completion survives a round trip without reopening either replay.")
	_check(_room.get_node("ChapterStatus").text.contains("向何青提交推理"), "The next objective points to He Qing once the evidence is collected.")
	_check(_log.entries().size() == 8 and _chapter.story_time() == "周四 18:40", "A completed route retains all eight records and the scene time.")
	await _complete_case(not backtrack)


func _complete_case(try_wrong_answer: bool) -> void:
	await _interact_at(Vector2(789, 303), "向何青提交推理")
	_check(_hud.header.text == "提交推理" and _hud.close_button.visible, "The reasoning panel can be closed for review.")
	var reasoning: Control = _hud.presentation_slot.get_node("Reasoning")
	var submit := reasoning.get_node("Submit") as Button
	_check(submit.disabled, "Both answers are required before submitting.")
	await _check_card("reasoning")
	if try_wrong_answer:
		_tap_button(_choice(reasoning, _chapter.ROUTE_CHOICES[1]))
		_tap_button(_choice(reasoning, _chapter.SOUND_CHOICES[1]))
		await _settle()
		await _capture("10-reasoning")
		_tap_button(submit)
		await _settle()
		_check(_hud.header.text == "提交推理" and not _room.get_node("Investigation/DrawerPoint").visible, "A wrong answer does not clear the case or unlock the drawer.")
		_close()
		await _settle()
		await _reread("待复核 · 拖响来源", "哪一段声响消失了")
		await _reread("推车复走", "前后轮照样磕过门槛")
		await _interact_at(Vector2(789, 303), "向何青提交推理")

	_tap_button(_choice(reasoning, _chapter.ROUTE_CHOICES[1]))
	_tap_button(_choice(reasoning, _chapter.SOUND_CHOICES[0]))
	await _settle()
	_tap_button(submit)
	await _settle()
	_check(_hud.header.text == "102 出入结论" and _log.has_entry(_chapter.CONCLUSION.id), "Correct reasoning records the conclusion and unlocks inventory.")
	_close()

	var original_desk: Vector2 = _room.get_node("WalkableFloor/DepthSort/LongDesk").position
	await _interact_at(Vector2(179, 267), "查看下层抽屉")
	_check(_hud.header.text == "102 下层抽屉" and _hud.evidence_action_button.text == "装入 A01", "Open the lower drawer at the scene.")
	var moved_desk: Vector2 = _room.get_node("WalkableFloor/DepthSort/LongDesk").position
	_check(moved_desk.y > original_desk.y, "Opening the drawer moves the desk and its collision shape.")
	await _check_card("drawer")
	await _capture("11-open-drawer")
	_close()
	if try_wrong_answer:
		await _return_to_yard()
		await _enter_102()
		_check(_room.get_node("Scenery/DrawerUnit/ExposedDrawer").visible, "The opened drawer persists across rooms.")
		_check(_room.get_node("WalkableFloor/DepthSort/LongDesk").position == moved_desk, "The desk shift persists across rooms.")
		await _walk_to(Vector2(370, 343))
	await _interact_at(Vector2(179, 267), "查看下层抽屉")
	_tap_button(_hud.evidence_action_button)
	await _settle()
	_check(_hud.header.text == "已装入 A01" and not _log.has_entry(_chapter.ARCHIVE_PHOTO.id), "Packing the ledger exposes the photo action without recording it.")
	_check(not _room.get_node("Investigation/SignOffPoint").visible, "Sign-off requires the photograph.")
	_close()
	await _interact_at(Vector2(279, 283), "查看 A01")
	_check(_hud.evidence_action_button.text == "拍下清点照片", "The photo action is offered when inspecting the box.")
	_tap_button(_hud.evidence_action_button)
	await _settle()
	_check(_hud.header.text == "A01 清点照片" and _hud.preview_container.visible, "Photograph shows the A01 box and ledger.")
	_check(_log.has_entry(_chapter.ARCHIVE_PHOTO.id), "The photograph is recorded.")
	await _check_card("A01 photograph")
	await _capture("12-a01-photograph")
	_close()
	await _interact_at(Vector2(371, 301), "请周闻签字")
	_check(_hud.header.text == "A01 清点单" and _hud.description.text.contains("已阅：周闻"), "Zhou Wen signs the inventory.")
	_check(_log.has_entry(_chapter.SIGNED_INVENTORY.id), "The signed inventory is recorded.")
	_close()

	await _return_to_yard()
	await _interact_at(Vector2(158, 346), "经外廊回走廊")
	await _room_ready("Corridor")
	await _interact_at(Vector2(610, 352), "回看 102 正门")
	_check(_hud.header.text == "第一章完 · 上锁的教室" and _chapter.case_stage == _chapter.CaseStage.COMPLETE, "The final look at the sealed door completes Chapter One.")
	await _check_card("chapter ending")
	await _capture("13-ending")
	if try_wrong_answer:
		_close()
	else:
		await _play_chapter_two()
	await _reread("A01 清点照片", "三针白色补线")
	await _reread("A01 清点单", "已阅：周闻")


func _play_chapter_two() -> void:
	_check(_hud.evidence_action_button.text == "开始第二章", "The ending offers the next chapter.")
	_tap_button(_hud.evidence_action_button)
	await _room_ready("FrontDesk")
	_check(_chapter_two.active and _room.get_node("ChapterStatus").text.begins_with("周五 17:20"), "The handoff starts Friday's investigation.")
	_check(_chapter.case_stage == _chapter.CaseStage.COMPLETE and _log.has_entry(_chapter.SIGNED_INVENTORY.id), "The handoff retains the entire Thursday investigation.")
	await _capture("14-chapter-two-front-desk")

	await _interact_at(Vector2(793, 344), "前往走廊")
	await _room_ready("Corridor")
	await _enter_back_yard()
	await _interact_at(Vector2(730, 346), "检查器材门")
	_check(current_scene == _room and not _chapter_two.can_revisit_102(), "Thursday's authorization does not unlock the Friday revisit by itself.")
	await _return_to_front_desk()

	await _walk_to(Vector2(257, 351))
	_press_e()
	await _settle()
	_check(_hud.header.text == "16:46 群聊原图" and _hud.preview_container.visible, "E records the timestamped photo and shows its preview.")
	await _check_card("16:46 photo")
	await _capture("15-chapter-two-photo")
	_tap_button(_hud.evidence_action_button)
	await _settle()
	_check(_hud.header.text == "群聊转发截图" and _log.has_entry(_chapter_two.FORWARDED_CROP.id), "The forwarded crop can be compared and recorded separately.")
	await _check_card("forwarded photo crop")
	await _capture("15b-chapter-two-photo-crop")
	_tap_button(_hud.evidence_action_button)
	await _settle()
	_check(_hud.header.text == "16:46 群聊原图", "The comparison returns to the original photo.")
	_close()
	await _settle()
	_check(not _chapter_two.can_revisit_102(), "Both timestamped clues are required for the revisit.")

	await _interact_at(Vector2(447, 351), "查看16:50 收页便签")
	_check(_hud.header.text == "16:50 收页便签" and _hud.description.text.contains("没有署名"), "The receipt records the time and does not identify the filer.")
	_close()
	await _settle()
	_check(_chapter_two.can_revisit_102() and not _chapter_two.can_submit_reasoning(), "The receipt unlocks 102, but the physical evidence is still required.")

	await _interact_at(Vector2(793, 344), "前往走廊")
	await _room_ready("Corridor")
	await _enter_back_yard()
	await _enter_102()
	await _reread("16:46 群聊原图", "月牙形咖啡渍")
	await _reread("16:50 收页便签", "摘录明早补")
	await _interact_at(Vector2(580, 290), "查看102 器材门旧轮痕")
	_check(_hud.header.text == "102 器材门旧轮痕", "The existing wheel track point records Friday's site observation.")
	_close()
	await _settle()
	await _walk_to(Vector2(370, 438))
	await _interact_at(Vector2(279, 283), "核对桌后 A01")
	_check(_hud.header.text == "102 桌后 A01" and _hud.description.text.contains("102 下层抽屉"), "Walking around the table reaches the physical comparison at A01.")
	await _check_card("Friday A01 comparison")
	await _capture("16-chapter-two-a01")
	_close()
	await _settle()
	_check(not _chapter_two.can_submit_reasoning(), "The 102 revisit alone cannot identify the original page.")
	await _return_to_yard()
	await _return_to_front_desk()
	await _reread("102 器材门旧轮痕", "折叠凳")
	await _reread("102 桌后 A01", "白色补线")

	await _interact_at(Vector2(540, 294), "查看登记夹与内袋")
	_check(_hud.header.text == "登记夹与内袋" and _hud.preview_container.visible, "The counter pocket reveals three partially covered originals.")
	await _check_card("front desk file pocket")
	await _capture("17-chapter-two-file-pocket")
	_close()
	await _settle()
	await _interact_at(Vector2(350, 360), "提交原页判断")
	var reasoning: Control = _hud.presentation_slot.get_node("Reasoning")
	var submit := reasoning.get_node("Submit") as Button
	_check(submit.disabled, "Both the order and location are required.")
	_tap_button(_choice(reasoning, _chapter_two.ORDER_CHOICES[1]))
	_tap_button(_choice(reasoning, _chapter_two.LOCATION_CHOICES[0]))
	_tap_button(submit)
	await _settle()
	_check(not _chapter_two.has_finding() and _hud.header.text == "核对周四原页", "A wrong location stays open for review.")
	await _check_card("page reasoning")
	await _capture("18-chapter-two-review")
	_close()
	await _settle()
	await _reread("待复核 · 原页去向", "比一比原图与内袋页角")
	await _reread("登记夹与内袋", "含联系方式的原页用完请收入前台内袋")
	await _interact_at(Vector2(350, 360), "提交原页判断")
	_tap_button(_choice(reasoning, _chapter_two.LOCATION_CHOICES[1]))
	_tap_button(submit)
	await _settle()
	_check(_hud.header.text == "原页去向已核对" and _chapter_two.has_finding(), "The correct comparison records the first finding.")
	_close()
	await _settle()
	await _reread("原页去向已核对", "日期和月牙污渍相符")


func _return_to_front_desk() -> void:
	await _interact_at(Vector2(158, 346), "经外廊回走廊")
	await _room_ready("Corridor")
	await _walk_to(Vector2(161, 344))
	_tap_button(_hud.interaction_button)
	await _room_ready("FrontDesk")
	_check(_player.position.is_equal_approx(Vector2(755, 374)), "Backtracking to the front desk uses the corridor entrance.")


func _choice(parent: Control, label: String) -> Button:
	for node in parent.find_children("*", "Button", true, false):
		if node.text == label:
			return node
	return null


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
	_check(not _chapter_two.active and not _chapter_two.has_finding() and not _room.get_node("Investigation/PhotoPoint").visible, "Restart also clears Friday's progress and restores the Thursday front desk.")
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
	_check(root.get_visible_rect().encloses(rect), "Evidence fits in the viewport: %s (%s)" % [context, rect])


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
