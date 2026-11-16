extends SceneTree
## End-to-end chapter routes through real HUD input.

var _failures := 0
var _room: Node
var _hud: CanvasLayer
var _player: CharacterBody2D
var _log: Node
var _chapter: Node
var _chapter_two: Node
var _chapter_three: Node
var _transition: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("/.test-runtime/"):
		push_error("Use an isolated .test-runtime user data folder for the chapter route test.")
		quit(1)
		return
	_log = root.get_node("InvestigationLog")
	_chapter = root.get_node("ChapterOne")
	_chapter_two = root.get_node("ChapterTwo")
	_chapter_three = root.get_node("ChapterThree")
	_transition = root.get_node("RoomTransition")
	change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	await scene_changed
	await _settle()
	_tap_button(current_scene.get_node("%NewGameButton"))
	await _room_ready("FrontDesk")
	_check(_log.entries().is_empty() and not _chapter.commission_accepted, "New game starts with an empty log and no commission.")
	_check(_room.get_node("Investigation/CorridorExit").disabled, "Receive the commission before leaving the front desk.")
	_check(not _room.get_node("Investigation/PhotoPoint").visible and not _chapter_two.can_start(), "Friday clues stay hidden before the chapter handoff.")
	_check(not _chapter_three.can_start(), "Saturday requires the Friday ending.")
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
	await _restart()
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
	_hud.get_node("PauseMenu").notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_check(paused and not joystick.visible and not joystick.is_engaged(), "Opening the pause menu releases an active joystick.")
	var paused_position := _player.global_position
	_hud.get_node("PauseMenu").notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _settle()
	_check(not paused and joystick.visible and _player.global_position.is_equal_approx(paused_position),
		"Resuming with the old touch still held does not move the player.")
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
	_check(not _room.get_node("Investigation/AccidentPoint").visible, "The west stair investigation waits for the rescheduled handover.")
	_check(not _room.get_node("Investigation/NightPatrolPoint").visible, "Night patrol cannot start on an early visit.")
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
	_check(not _chapter_two.can_submit_reasoning(), "The photographer still needs to confirm the circumstances.")
	await _interact_at(Vector2(570, 360), "请邵宁联系发图人")
	_check(_hud.header.text == "发图人的证词" and _chapter_two.can_submit_reasoning(), "Shao Ning helps confirm when and why the photo was posted.")
	_close()
	await _settle()
	await _interact_at(Vector2(350, 360), "提交原页判断")
	var reasoning: Control = _hud.presentation_slot.get_node("Reasoning")
	var submit := reasoning.get_node("Submit") as Button
	_check(submit.disabled and reasoning.find_child("VisitorFilePocket", true, false) != null, "The form presents the three originals and requires both selections.")
	_tap_button(_choice(reasoning, _chapter_two.ORDER_CHOICES[1]))
	_tap_button(_choice(reasoning, _chapter_two.PAGE_CHOICES[0]))
	_tap_button(submit)
	await _settle()
	_check(not _chapter_two.has_finding() and _hud.header.text == "核对周四原页", "A wrong page stays open for review.")
	await _check_card("page reasoning")
	await _capture("18-chapter-two-review")
	_close()
	await _settle()
	await _reread("待复核 · 原页比对", "比一比原图与内袋页角")
	await _reread("登记夹与内袋", "含联系方式的原页用完请收入前台内袋")
	await _interact_at(Vector2(350, 360), "提交原页判断")
	_tap_button(_choice(reasoning, _chapter_two.PAGE_CHOICES[1]))
	_tap_button(submit)
	await _settle()
	_check(_hud.header.text == "原页去向已核对" and _chapter_two.has_finding(), "The correct comparison records the first finding.")
	_close()
	await _settle()
	await _reread("原页去向已核对", "日期和月牙污渍相符")

	await _interact_at(Vector2(570, 360), "向邵宁确认收页")
	_check(_hud.header.text == "邵宁确认收页" and _log.has_entry(_chapter_two.PHOTO.id), "The complete photo is still available until the player archives the excerpt.")
	_close()
	await _settle()
	await _interact_at(Vector2(793, 344), "前往走廊")
	await _room_ready("Corridor")
	await _interact_at(Vector2(161, 344), "返回前台")
	await _room_ready("FrontDesk")
	await _interact_at(Vector2(570, 360), "向邵宁确认收页")
	_tap_button(_hud.evidence_action_button)
	await _settle()
	_check(_hud.header.text == "16:46 群聊照片局部留档", "Archiving the cropped detail shows the replacement evidence.")
	_check(_chapter_two.has_withdrawn_photo() and _chapter_two.can_revisit_102(), "Withdrawing the larger photos keeps the evidence path open.")
	_check(not _log.has_entry(_chapter_two.PHOTO.id) and not _log.has_entry(_chapter_two.FORWARDED_CROP.id), "The original and forwarded crop are withdrawn from the notebook.")
	await _check_card("photo excerpt")
	await _capture("19-chapter-two-excerpt")
	_close()
	await _settle()
	await _reread("16:46 群聊照片局部留档", "日期、白杯和带月牙污渍的纸角")
	await _interact_at(Vector2(257, 351), "查看16:46 群聊照片局部留档")
	_check(not _hud.evidence_action_button.visible and not _log.has_entry(_chapter_two.PHOTO.id), "The counter phone opens the excerpt without a path to restore the withdrawn photo.")
	_close()
	await _settle()

	await _interact_at(Vector2(655, 345), "查看102 原地复核改签")
	_check(_hud.description.text.contains("19:10") and _hud.description.text.contains("19:30"), "The notice records both times and the new location.")
	await _check_card("revised handover")
	await _capture("20-chapter-two-handover")
	_close()
	await _settle()
	var watch_pickup := "--watch-pickup" in OS.get_cmdline_user_args()
	if watch_pickup:
		await _interact_at(Vector2(715, 352), "问周闻收了什么")
		_check(_log.has_entry(_chapter_two.SPRING_LEDGER.id) and not _room.get_node("Scenery/RecycleBasket/SpringLedger").visible, "Seeing the optional pickup records it and removes the book from the basket.")
		_close()
		await _settle()
	await _interact_at(Vector2(793, 344), "前往走廊")
	await _room_ready("Corridor")
	_check(not _room.get_node("Investigation/NightPatrolPoint").visible, "Night patrol waits for the accident photograph.")
	await _interact_at(Vector2(350, 346), "拍下旧事故说明")
	_check(_hud.header.text == "西梯旧事故说明照片" and _hud.description.text.contains("事发前未收到"), "The west stair notice is preserved for a later comparison.")
	await _check_card("old accident notice")
	await _capture("21-chapter-two-accident")
	_close()
	await _settle()
	await _interact_at(Vector2(610, 352), "查看韩素夜巡")
	_check(_hud.header.text == "周五 21:10 · 韩素巡楼" and _hud.preview_container.visible, "The door window shows the night patrol.")
	await _check_card("night patrol")
	await _capture("22-chapter-two-night-patrol")
	_tap_button(_hud.evidence_action_button)
	await _settle()
	_check(_chapter_two.is_complete() and not _chapter_two.can_revisit_102(), "Reading Han Su's message ends the Friday investigation and locks the supply door.")
	_check(_log.has_entry(_chapter_two.SPRING_LEDGER.id) == watch_pickup, "The optional spring ledger clue is tracked independently of chapter completion.")
	_tap_button(_hud.evidence_action_button)
	await _settle()
	_check(_hud.header.text == "第二章完 · 少掉的一页" and _hud.description.text.contains("雨棚下的人"), "The ending points to Chapter Three.")
	_check(_hud.evidence_action_button.text == "开始第三章", "The Friday ending can start Saturday.")
	await _check_card("Friday ending")
	await _capture("23-chapter-two-ending")
	await _play_chapter_three(watch_pickup)
	await _reread("韩素的 21:10 夜巡消息", "今天两边门我都锁了")
	await _reread("西梯旧事故说明照片", "落款：周闻")
	await _reread("102 原地复核改签", "A01 保持开箱")
	await _reread("16:46 群聊照片局部留档", "邵宁确认")


func _play_chapter_three(start_directly: bool) -> void:
	if not start_directly:
		_close()
		await _settle()
		await _interact_at(Vector2(610, 352), "回看夜巡消息")
		_tap_button(_hud.evidence_action_button)
		await _settle()
		_check(_hud.header.text == "第二章完 · 少掉的一页", "The Friday ending reopens after dismissal.")
	_tap_button(_hud.evidence_action_button)
	await _room_ready("Corridor")
	_check(_chapter_three.active and _room.get_node("ChapterStatus").text.begins_with("周六 17:50"), "The handoff starts on Saturday.")
	_check(not _room.get_node("Scenery/NightShade").visible and not _room.get_node("Investigation/NightPatrolPoint").visible, "Saturday replaces Friday's night patrol at the door.")
	await _capture("24-chapter-three-corridor")

	await _interact_at(Vector2(465, 395), "找韩素了解夜巡")
	_check(_log.has_entry(_chapter_three.COMMISSION.id), "Han Su's commission unlocks the high window.")
	_close()
	await _interact_at(Vector2(647, 348), "查看102 正门封条")
	_check(_hud.header.text == "102 正门封条", "Saturday's seal remains inspectable.")
	_close()

	await _enter_back_yard()
	await _interact_at(Vector2(730, 346), "检查器材门")
	_check(not _transition.is_changing and _room.get_node("WalkHint").text.contains("正门高窗"), "An early visit to the yard points back to the high window.")
	await _interact_at(Vector2(158, 346), "经外廊回走廊")
	await _room_ready("Corridor")
	await _interact_at(Vector2(588, 345), "查看正门高窗")
	_check(_hud.header.text == "正门高窗" and _log.has_entry(_chapter_three.HIGH_WINDOW.id), "The high-window observation records its own evidence.")
	await _check_card("high window observation")
	await _capture("25-chapter-three-high-window")
	_close()
	_tap_button(_hud.get_node("NotebookButton"))
	await _settle()
	_check(_notebook_button("对照高窗与桌后") == null, "The notebook waits for both observations before offering comparison.")
	_close()

	await _enter_back_yard()
	await _interact_at(Vector2(730, 346), "检查器材门")
	_check(_room.get_node("WalkHint").text.contains("请韩素打开器材门"), "The high window gives a new way to open the supply door.")
	await _interact_at(Vector2(390, 367), "请韩素打开器材门")
	_check(_chapter_three.can_enter_supply_door() and _hud.header.text == "周六器材门", "Han Su opens the door for Saturday.")
	_close()
	await _enter_102()
	await _walk_to(Vector2(690, 426))
	_tap(Vector2(656, 173))
	await _settle()
	_check(not _hud.is_open() and not _log.has_entry(_chapter_three.DESK_VIEW.id), "The glass cannot be examined from the front of the long desk.")
	await _interact_at(Vector2(655, 265), "查看桌后观察")
	_check(_hud.header.text == "桌后观察" and _chapter_three.can_submit_location(), "Walking around the desk records the second view and unlocks the finding.")
	await _check_card("desk observation")
	await _capture("26-chapter-three-desk-view")
	_close()
	await _return_to_yard()
	_check(_chapter_three.can_enter_supply_door(), "The Saturday door stays open on backtracking.")
	await _interact_at(Vector2(158, 346), "经外廊回走廊")
	await _room_ready("Corridor")

	await _interact_at(Vector2(465, 395), "向韩素说明人影位置")
	var form := _hud.presentation_slot.get_node("LocationReasoning") as Control
	var submit := form.get_node("Submit") as Button
	_check(submit.disabled, "The placement decision requires a selected answer.")
	_tap_button(_choice(form, "在 102 教室里"))
	_tap_button(submit)
	await _settle()
	_check(not _chapter_three.has_location_finding() and form.find_children("*", "Label", false, false)[0].text.contains("玻璃边框"), "A wrong choice points to visible evidence and allows recovery.")
	_close()

	_tap_button(_hud.get_node("NotebookButton"))
	await _settle()
	var compare := _notebook_button("对照高窗与桌后")
	await _settle()
	_tap_button(compare)
	await _settle()
	_check(_hud.header.text == "对照高窗与桌后" and not form.visible, "The notebook compares both observations without the reasoning form over it.")
	await _check_card("shelter comparison")
	await _capture("27-chapter-three-comparison")
	for view in ["正门高窗", "桌后观察"]:
		_tap_button(_choice(_hud.presentation_slot, "放大" + view))
		await _settle()
		_check(_hud.header.text == view and _hud.close_button.text == "返回对照", "An enlarged view can return directly to comparison.")
		await _check_card("enlarged " + view)
		_close()
		await _settle()
		_check(_hud.header.text == "对照高窗与桌后", "Returning to comparison preserves both views.")
	_close()
	await _settle()
	_check(_hud.header.text == "笔记" and _hud.notebook.visible, "Closing comparison returns to the notebook.")
	_close()

	await _interact_at(Vector2(465, 395), "向韩素说明人影位置")
	_tap_button(_choice(form, "在玻璃外的后院雨棚"))
	_tap_button(submit)
	await _settle()
	_check(_chapter_three.has_location_finding() and _hud.header.text == "人影在雨棚", "The correct finding completes the Saturday observation route.")
	await _check_card("shelter finding")
	await _capture("28-chapter-three-finding")
	var record_count: int = _log.entries().size()
	_close()
	await _interact_at(Vector2(465, 395), "回看人影位置")
	_check(_log.entries().size() == record_count, "Reopening the finding is idempotent.")
	_close()
	await _reread("人影在雨棚", "黄色卷尺")
	await _play_saturday_return()


func _play_saturday_return() -> void:
	await _enter_back_yard()
	await _interact_at(Vector2(626, 345), "查看门铃旁的留言")
	_check(_hud.description.text.contains("脚有一个白的"), "The mailbox records both clues to identify the item.")
	_close()
	await _return_to_front_desk()
	_check(not _chapter_three.can_confirm_appointment() and not _room.get_node("Investigation/DutyBoardPoint").visible,
		"The appointment is unavailable before matching the loan card and talking to Han Su.")
	await _interact_at(Vector2(246, 350), "核对三张借用卡")
	var cards := _hud.presentation_slot.get_node("LoanCards") as Control
	await _check_card("three loan cards")
	await _capture("29-chapter-three-loan-cards")
	var submit_card := cards.get_node("Submit") as Button
	for answer in [_chapter_three.Loan.REEL, _chapter_three.Loan.BLACK_STAND]:
		_tap_button(_choice(cards, _chapter_three.LOAN_CHOICES[answer]))
		_tap_button(submit_card)
		await _settle()
		_check(not _log.has_entry(_chapter_three.LOAN_CARD.id) and cards.visible,
			"Wrong cards can be reconsidered without recording a match.")
	_tap_button(_choice(cards, _chapter_three.LOAN_CHOICES[_chapter_three.Loan.WHITE_STAND]))
	_tap_button(submit_card)
	await _settle()
	_check(_hud.header.text == "12 号谱架借用卡" and _hud.description.text.contains("许南"), "The confirmed card records the borrower.")
	_close()
	await _interact_at(Vector2(466, 350), "查看借用物交回通知")
	_check(_hud.description.text.contains("散场前") and _hud.description.text.contains("斜贴角"),
		"The notice records the original wording and what Zhou Wen left on the board.")
	await _check_card("return notice")
	_close()
	await _interact_at(Vector2(552, 387), "给韩素看交回通知")
	_check(_hud.description.text.contains("七点二十五") and not _chapter_three.can_confirm_appointment(),
		"The call establishes the place and time before the duty board is updated.")
	_close()
	await _interact_at(Vector2(655, 345), "登记赴约安排")
	_check(_hud.evidence_action_button.text == "确认赴约" and _chapter_three.can_confirm_appointment(),
		"The duty board is the final prerequisite for the explicit time advance.")
	_close()
	await _interact_at(Vector2(793, 344), "前往走廊")
	await _room_ready("Corridor")
	_check(not _chapter_three.appointment_started and _chapter_three.status().begins_with("周六 17:50"),
		"The player can leave to recheck evidence without advancing time.")
	await _interact_at(Vector2(161, 344), "返回前台")
	await _room_ready("FrontDesk")
	await _interact_at(Vector2(655, 345), "查看赴约安排")
	_tap_button(_hud.evidence_action_button)
	await _room_ready("Room102")
	_check(_chapter_three.appointment_started and _chapter_three.status().begins_with("周六 19:25"),
		"Confirming the duty board advances time only after Room 102 loads.")
	await _interact_at(Vector2(483, 257), "返回后院")
	_check(not _transition.is_changing and current_scene == _room and _room.get_node("WalkHint").text.contains("A01"),
		"Trying to leave before taking the 19:25 record points back to the archive.")
	await _capture("30-chapter-three-appointment-room")
	await _interact_at(Vector2(279, 283), "查看19:25 · 离开 102 前")
	_check(_hud.description.text.contains("白线朝上") and _hud.description.text.contains("G03"),
		"Departure records the visible white stitching, desk and open equipment box.")
	await _check_card("departure record")
	await _capture("31-chapter-three-departure-record")
	_close()
	await _interact_at(Vector2(483, 257), "随韩素去雨棚")
	await _room_ready("BackYard")
	_check(not _room.get_node("Investigation/ReturnSignOffPoint").visible, "Inspect the returned item before asking Han Su to sign.")
	await _interact_at(Vector2(594, 379), "核对许南带来的谱架")
	_check(_hud.description.text.contains("桌脚蹭地") and _hud.description.text.contains("白色替换件"),
		"The stand records the audible clue, Xu Nan's account and the physical match.")
	await _check_card("returned stand")
	await _capture("32-chapter-three-returned-stand")
	_close()
	await _interact_at(Vector2(657, 379), "请韩素签收")
	_check(_hud.header.text == "19:27 · 后院签收联" and _chapter_three.can_submit_conclusion(),
		"The signed receipt sets the final time and unlocks the conclusion.")
	_close()
	await _interact_at(Vector2(657, 379), "向韩素提交归还结论")
	var form := _hud.presentation_slot.get_node("ReturnReasoning") as Control
	var submit := form.get_node("Submit") as Button
	_tap_button(_choice(form, _chapter_three.VISITOR_CHOICES[_chapter_three.Visitor.XU_NAN]))
	_tap_button(_choice(form, _chapter_three.RETURN_CHOICES[_chapter_three.Loan.REEL]))
	_tap_button(submit)
	await _settle()
	_check(not _chapter_three.is_complete() and form.visible, "A wrong conclusion does not end the chapter.")
	_tap_button(_choice(form, _chapter_three.RETURN_CHOICES[_chapter_three.Loan.WHITE_STAND]))
	_tap_button(submit)
	await _settle()
	_check(_chapter_three.is_complete() and _hud.header.text == "第三章完", "The correct conclusion completes Chapter Three.")
	await _check_card("Chapter Three ending")
	await _capture("33-chapter-three-ending")
	var records: int = _log.entries().size()
	_close()
	await _interact_at(Vector2(657, 379), "回看第三章结案")
	_check(_log.entries().size() == records, "Reopening the chapter ending preserves unique evidence entries.")
	_close()
	await _interact_at(Vector2(657, 379), "回看第三章结案")
	_tap_button(_hud.evidence_action_button)
	await _room_ready("Room102")
	_check(_chapter_three.final_review_started and _chapter_three.status().begins_with("周六 19:28"),
		"The chapter ending starts the 19:28 handover review in the same room.")
	_check(_room.get_node("Scenery/ArchiveBox/CupRing").visible
		and not _room.get_node("Scenery/ArchiveBox/Ledger/WhiteStitches").visible,
		"The moved A01 box now visibly contains the spring ledger.")
	_check(_room.get_node("Scenery/ClosedG03/Thread").is_visible_in_tree()
		and not _room.get_node("Scenery/OpenG03").visible, "The G03 lid is closed, with a visible thread.")
	_check(not _room.get_node("Investigation/G03Point").visible
		and not _room.get_node("Investigation/FinalHeQingPoint").visible
		and not _room.get_node("Investigation/FinalHanSuPoint").visible
		and not _room.get_node("Investigation/YardExit").visible,
		"G03 and the final witnesses stay unavailable before the handover is paused.")
	await _interact_at(Vector2(310, 449), "复核 A01 箱口的报修册")
	_check(_hud.header.text == "2019 年春季报修册" and _hud.description.text.contains("书脊完整"),
		"The spring ledger shows its identifying details.")
	_tap_button(_hud.evidence_action_button)
	await _check_card("A01 comparison")
	_check(_hud.header.text == "复核 A01" and not _chapter_three.handover_paused,
		"Opening the comparison leaves the handover pending.")
	_close()
	await _settle()
	_check(_hud.header.text == "2019 年春季报修册" and not _chapter_three.handover_paused,
		"The player can leave the comparison without objecting.")
	_tap_button(_hud.evidence_action_button)
	await _settle()
	for view in ["A01 清点照片", "2019 年春季报修册"]:
		_tap_button(_choice(_hud.presentation_slot, "放大" + view))
		await _check_card(view)
		var detail := "三针白色补线" if view == "A01 清点照片" else "书脊完整"
		_check(_hud.header.text == view and _hud.description.text.contains(detail),
			"Each item can be enlarged to check its spine.")
		_close()
		await _settle()
		_check(_hud.header.text == "复核 A01", "The enlarged item returns to the comparison.")
	_tap_button(_choice(_hud.presentation_slot, "提出异议并暂停移交"))
	_check(_chapter_three.handover_paused and _log.has_entry(_chapter_three.FINAL_REVIEW.id)
		and _hud.header.text == "终章复核 · A01 与首次清点不符",
		"The discrepancy pauses the handover and is retained in the notebook.")
	_close()
	await _play_final_ledger()
	await _reread("终章复核 · A01 与首次清点不符", "暂停 A01")
	await _reread("19:25 · 离开 102 前", "三针白线")
	await _reread("19:27 · 后院签收联", "韩素")


func _play_final_ledger() -> void:
	_check(_room.get_node("Investigation/G03Point").visible
		and _room.get_node("Investigation/FinalHeQingPoint").visible
		and _room.get_node("Investigation/FinalHanSuPoint").visible,
		"Pausing the handover exposes G03 and both witness points.")
	await _walk_to(Vector2(620, 378))
	_tap(Vector2(697, 248))
	await _settle()
	_check(not _hud.is_open() and not _log.has_entry(_chapter_three.G03_CARD.id),
		"G03 cannot be inspected from the front of the long desk.")
	await _interact_at(Vector2(697, 286), "检查 G03")
	_check(_hud.header.text.contains("G03"), "G03 can be inspected from its rear side after the pause.")
	_check(_hud.evidence_action_button.text == "检查箱缝", "The closed G03 box first offers the seam check.")
	_close()
	await _interact_at(Vector2(697, 286), "检查 G03")
	_check(_hud.evidence_action_button.text == "检查箱缝", "Reopening the card page preserves the seam check action.")
	_tap_button(_hud.evidence_action_button)
	await _settle()
	_check(_hud.evidence_action_button.text == "拍下箱缝和装载卡", "The seam check leads to a photo action.")
	_tap_button(_hud.evidence_action_button)
	await _settle()
	_check(_log.has_entry(_chapter_three.G03_PHOTO.id), "The G03 seam and loading card are photographed.")
	_close()
	await _interact_at(Vector2(795, 335), "请打开 G03")
	_check(_log.has_entry(_chapter_three.G03_PERMISSION.id), "He Qing grants permission to open G03.")
	_close()
	await _interact_at(Vector2(697, 286), "检查 G03")
	_check(_hud.evidence_action_button.text == "打开 G03", "Permission exposes the G03 opening action.")
	_tap_button(_hud.evidence_action_button)
	await _settle()
	_check(_hud.evidence_action_button.text == "移开谱架，取出秋册", "The open box offers retrieval of the autumn ledger.")
	_tap_button(_hud.evidence_action_button)
	await _settle()
	_check(_log.has_entry(_chapter_three.AUTUMN_LEDGER.id), "Retrieving G03 records the autumn ledger.")
	_check(_hud.header.text == _chapter_three.AUTUMN_LEDGER.title
		and _hud.evidence_action_button.text == "翻看目录",
		"The autumn ledger card offers its directory immediately after retrieval.")
	_close()
	await _reread(_chapter_three.AUTUMN_LEDGER.title, "G03")
	await _play_a047()
	await _interact_at(Vector2(750, 335), "向韩素核对离场情况")
	_check(_log.has_entry(_chapter_three.HAN_SU_TESTIMONY.id), "Han Su's departure testimony is recorded.")
	_close()

	await _interact_at(Vector2(483, 257), "返回后院")
	await _room_ready("BackYard")
	await _interact_at(Vector2(158, 346), "经外廊回走廊")
	await _room_ready("Corridor")
	await _interact_at(Vector2(161, 344), "返回前台")
	await _room_ready("FrontDesk")
	await _interact_at(Vector2(570, 360), "向邵宁核对春册去向")
	_check(_log.has_entry(_chapter_three.SHAO_NING_TESTIMONY.id), "Shao Ning's spring ledger testimony is recorded.")
	_close()
	await _interact_at(Vector2(793, 344), "前往走廊")
	await _room_ready("Corridor")
	await _interact_at(Vector2(783, 344), "经外廊去后院")
	await _room_ready("BackYard")
	await _interact_at(Vector2(730, 346), "从器材门回 102")
	await _room_ready("Room102")
	await _reread(_chapter_three.G03_PHOTO.title, "G03")
	await _reread(_chapter_three.HAN_SU_TESTIMONY.title, "韩素")
	await _reread(_chapter_three.SHAO_NING_TESTIMONY.title, "邵宁")
	await _resume_after_final_ledger()


func _resume_after_final_ledger() -> void:
	_tap_button(_hud.get_node("PauseButton"))
	await _settle()
	_check(paused, "Pause the recovered-ledger investigation before returning to the menu.")
	_tap_button(_hud.get_node("PauseMenu/%ReturnButton"))
	await scene_changed
	await _settle()
	_check(current_scene.name == "MainMenu" and not paused, "Return to the main menu after recovering the ledger.")
	_tap_button(current_scene.get_node("%ContinueButton"))
	await _room_ready("Room102")
	_check(_chapter_three.handover_paused and _log.has_entry(_chapter_three.AUTUMN_LEDGER.id)
		and _log.has_entry(_chapter_three.HAN_SU_TESTIMONY.id)
		and _log.has_entry(_chapter_three.SHAO_NING_TESTIMONY.id),
		"Continue restores the recovered ledger and both testimonies.")
	_check(_room.get_node("Scenery/OpenG03").visible and not _room.get_node("Scenery/ClosedG03").visible,
		"The G03 lid remains open after restarting the investigation.")
	_check(_room.get_node("Investigation/G03Point").interaction_label == "检查 G03",
		"The recovered-ledger interaction stays labeled 检查 G03 after reading A-047.")
	_check(_log.has_entry(_chapter_three.A047_REPORT.id)
		and _log.has_entry(_chapter_three.A047_FINDING.id),
		"Continue restores the A-047 report and final comparison conclusion.")
	await _reread(_chapter_three.A047_REPORT.title, "17:52")
	await _reread(_chapter_three.A047_FINDING.title, "故障报告在事故发生前已收到")
	await _interact_at(Vector2(697, 286), "检查 G03")
	_check(_hud.evidence_action_button.text == "翻看目录",
		"Reopening the autumn ledger still offers its directory.")
	_tap_button(_hud.evidence_action_button)
	await _settle()
	_check(_hud.header.text == "2019 年秋季报修册目录"
		and _hud.evidence_action_button.text == "打开 A-047",
		"The directory can still open A-047 after restart.")
	_tap_button(_hud.evidence_action_button)
	await _settle()
	_check(_hud.header.text == _chapter_three.A047_REPORT.title,
		"Reopening A-047 shows its saved report.")
	_tap_button(_hud.evidence_action_button)
	await _settle()
	_check(_hud.header.text == "核对旧事故说明"
		and _choice(_hud.presentation_slot, "指出有误的一句") == null,
		"The saved comparison is view-only after the finding.")
	_close()
	await _settle()
	_close()
	await _settle()
	_check(_chapter_three.status().contains("旧事故说明已核对"),
		"The final objective reports that the old incident statement was checked.")


func _play_a047() -> void:
	_check(_room.get_node("Investigation/G03Point").interaction_label == "检查 G03",
		"G03 keeps its familiar interaction label while holding the autumn ledger.")
	await _interact_at(Vector2(697, 286), "检查 G03")
	_check(_hud.header.text == _chapter_three.AUTUMN_LEDGER.title
		and _hud.evidence_action_button.text == "翻看目录",
		"The autumn ledger card opens its directory.")
	_tap_button(_hud.evidence_action_button)
	await _settle()
	_check(_hud.header.text == "2019 年秋季报修册目录"
		and _hud.evidence_action_button.text == "打开 A-047",
		"The directory offers the A-047 report.")
	_tap_button(_hud.evidence_action_button)
	await _settle()
	_check(_hud.header.text == "A-047 西梯应急灯报修存根"
		and _log.has_entry(&"final_a047_report")
		and _log.has_entry(_chapter_three.A047_REPORT.id),
		"Opening A-047 logs the report evidence.")
	_check(_hud.evidence_action_button.text == "对照旧事故说明"
		and _hud.get_node("%EvidenceSecondaryAction").text == "翻到次日维修记录",
		"The report offers comparison and the optional next-day repair stub.")
	_tap_button(_hud.get_node("%EvidenceSecondaryAction"))
	await _settle()
	_check(_hud.header.text == _chapter_three.A047_REPAIR.title
		and _log.has_entry(_chapter_three.A047_REPAIR.id)
		and _hud.evidence_action_button.text == "返回 A-047",
		"The optional repair stub is recorded and can return to A-047.")
	_tap_button(_hud.evidence_action_button)
	await _settle()
	_check(_hud.header.text == _chapter_three.A047_REPORT.title,
		"The repair stub returns to the A-047 report.")
	_tap_button(_hud.evidence_action_button)
	await _settle()
	_check(_hud.header.text == "核对旧事故说明" and not _chapter_three.needs_accident_photo(),
		"The report opens its comparison and enables the decision.")
	for view in [_chapter_three.A047_REPORT, _chapter_two.ACCIDENT_NOTICE]:
		var enlarge := _choice(_hud.presentation_slot, "放大" + view.title)
		_check(enlarge != null, "The comparison can enlarge " + view.title)
		if enlarge == null:
			continue
		_tap_button(enlarge)
		await _settle()
		_check(_hud.header.text == view.title and _hud.close_button.text == "返回对照",
			"The comparison enlargement returns to the old-statement comparison.")
		_close()
		await _settle()
		_check(_hud.header.text == "核对旧事故说明", "The comparison remains open after enlargement.")
	_tap_button(_choice(_hud.presentation_slot, "指出有误的一句"))
	await _settle()
	var form := _hud.presentation_slot.get_node("FinalAccidentReasoning") as Control
	_check(form != null and _hud.header.text == "核对旧事故说明",
		"The comparison opens the final accident reasoning form.")
	if form == null:
		return
	var submit := form.get_node("Submit") as Button
	_check(submit.disabled, "The reasoning form requires an answer selection.")
	_tap_button(_choice(form, "约 20:17 楼内停电"))
	_tap_button(submit)
	await _settle()
	var feedback: String = form.find_children("*", "Label", false, false)[0].text
	_check(not _log.has_entry(_chapter_three.A047_FINDING.id)
		and feedback.contains("17:52") and feedback.contains("20:17"),
		"A wrong sentence points to the conflicting times without recording a conclusion.")
	_close()
	await _settle()
	_check(_hud.header.text == "核对旧事故说明", "Closing wrong feedback returns to the comparison.")
	_tap_button(_choice(_hud.presentation_slot, "指出有误的一句"))
	await _settle()
	form = _hud.presentation_slot.get_node("FinalAccidentReasoning") as Control
	submit = form.get_node("Submit") as Button
	_tap_button(_choice(form, "事发前未收到西梯应急照明故障报告"))
	_tap_button(submit)
	await _settle()
	_check(_log.has_entry(&"final_a047_finding")
		and _log.has_entry(_chapter_three.A047_FINDING.id)
		and _hud.header.text == _chapter_three.A047_FINDING.title,
		"The correct sentence records the A-047 finding.")
	_close()
	await _settle()
	_check(not _hud.is_open(), "Closing the recorded conclusion returns to the room.")


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
	var recorded: int = _log.entries().size()
	_tap_button(_hud.get_node("PauseButton"))
	_check(paused, "Pause the investigation before leaving.")
	_tap_button(_hud.get_node("PauseMenu/%ReturnButton"))
	await scene_changed
	await _settle()
	var menu := current_scene
	_check(menu.name == &"MainMenu" and not paused, "The pause menu returns to the main menu.")
	_tap_button(menu.get_node("%NewGameButton"))
	await _settle()
	_check(_log.entries().size() == recorded, "The restart confirmation does not clear progress prematurely.")
	_tap_button(menu.get_node("%CancelButton"))
	await _settle()
	_check(menu.get_node("%ContinueButton").visible, "Cancelling keeps the saved investigation available.")
	_tap_button(menu.get_node("%NewGameButton"))
	await _settle()
	_tap_button(menu.get_node("%ConfirmButton"))
	await _room_ready("FrontDesk")
	_check(_log.entries().is_empty() and not _chapter.commission_accepted and not _chapter.corridor_visited, "Restart clears every note and first-chapter flag.")
	_check(not _chapter_two.active and not _chapter_two.has_finding() and not _room.get_node("Investigation/PhotoPoint").visible, "Restart also clears Friday's progress and restores the Thursday front desk.")
	_check(not _chapter_three.active and not _chapter_three.has_location_finding() and _chapter_three.observation_pair().is_empty(), "Restart also clears Saturday's progress and comparison.")
	_check(not _chapter_three.appointment_started and not _chapter_three.is_complete(), "Restart clears the appointment and Saturday conclusion.")
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
	await process_frame
	RenderingServer.force_draw(false)
	var screenshot := root.get_texture().get_image()
	_check(screenshot != null, "Rendered screenshot: " + label)
	if screenshot != null:
		var output := "res://../.test-runtime/" + label + ".png"
		_check(screenshot.save_png(output) == OK, "Saved screenshot: " + label)


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
