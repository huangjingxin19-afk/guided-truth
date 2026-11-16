extends SceneTree
## Run each phase in order in a separate process using an isolated .test-runtime data folder.

var _log: Node
var _one: Node
var _two: Node
var _three: Node
var _transition: Node
var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("/.test-runtime/"):
		push_error("Use an isolated .test-runtime user data folder for the autosave test.")
		quit(1)
		return
	_log = root.get_node("InvestigationLog")
	_one = root.get_node("ChapterOne")
	_two = root.get_node("ChapterTwo")
	_three = root.get_node("ChapterThree")
	_transition = root.get_node("RoomTransition")
	var args := OS.get_cmdline_user_args()
	var phase := args[0] if args.size() == 1 else ""
	if not await _enter_from_menu(phase):
		quit(1)
		return

	match phase:
		"first":
			await _save_first_chapter()
		"second":
			await _resume_first_and_save_second()
		"third":
			await _resume_second_and_save_third()
		"appointment-plan":
			await _resume_legacy_saturday_and_plan_appointment()
		"appointment-start":
			_check(current_scene.name == &"FrontDesk" and _three.can_confirm_appointment(),
				"The saved duty board can still be confirmed after restart.")
			_transition.start_saturday_appointment()
			await _settle()
			_check(current_scene.name == &"Room102" and _three.appointment_started, "Confirming starts the 19:25 scene.")
		"appointment-return":
			_check(current_scene.name == &"Room102" and _three.appointment_started and not _three.has_departure_record(),
				"Resume the 19:25 appointment at 102 before recording the scene.")
			_check(not current_scene.get_node("Investigation/YardExit").travel_allowed,
				"The restored 102 door waits for the departure record.")
			_log.record(_three.DEPARTURE)
			_transition.change_room("res://rooms/back_yard.tscn", &"FromRoom102")
			await _settle()
			_log.record(_three.RETURNED_STAND)
			_log.record(_three.RECEIPT)
			await _settle()
		"appointment-finish":
			_check(current_scene.name == &"BackYard" and _three.can_submit_conclusion()
				and _three.status().begins_with("周六 19:27"), "Resume the yard after signing, ready to submit the conclusion.")
			_check(_three.submit_conclusion(_three.Visitor.XU_NAN, _three.Loan.WHITE_STAND).is_empty(),
				"Submit the correct conclusion after restarting.")
			await _settle()
		"appointment-complete":
			_check(current_scene.name == &"BackYard" and _three.is_complete() and _three.has_departure_record(),
				"The conclusion and the 19:25 record survive together.")
			_check(_log.has_entry(_three.RECEIPT.id) and _log.has_entry(_three.RETURN_NOTICE.id),
				"Evidence for the final chapter remains in the notebook.")
		"final-review-start":
			_check(current_scene.name == &"BackYard" and _three.can_start_final_review(),
				"The completed Saturday case can enter the final review.")
			_transition.start_final_review()
			await _settle()
			_check(current_scene.name == &"Room102" and _three.final_review_started,
				"The final review starts in the 19:28 room state.")
			_three.pause_handover()
			await _settle()
			_check(_three.handover_paused and _log.has_entry(_three.FINAL_REVIEW.id),
				"Pausing the handover records the discrepancy.")
		"final-review-resume":
			_check(current_scene.name == &"Room102" and _three.final_review_started and _three.handover_paused,
				"Continue resumes the 19:28 review after pausing the handover.")
			_check(_log.has_entry(_three.FINAL_REVIEW.id)
				and current_scene.get_node("Scenery/ArchiveBox/CupRing").visible,
				"The discrepancy and spring ledger scene survive the restart.")
			_check(not _log.has_entry(_three.G03_CARD.id) and not _log.has_entry(_three.AUTUMN_LEDGER.id),
				"The legacy paused-handover save loads without inventing final evidence.")
			for entry in _three.FINAL_BOX_ENTRIES:
				_three.record_final_evidence(entry)
			for entry in _three.FINAL_WITNESSES:
				_three.record_final_evidence(entry)
			await _settle()
		"final-evidence-resume":
			_check(current_scene.name == &"Room102" and _three.handover_paused,
				"Continue restores the paused handover after final evidence was saved.")
			for entry in _three.FINAL_BOX_ENTRIES:
				_check(_log.has_entry(entry.id), "Restored final evidence: " + entry.title)
			for entry in _three.FINAL_WITNESSES:
				_check(_log.has_entry(entry.id), "Restored optional testimony: " + entry.title)
			_check(_three.status().contains("秋册已找回"), "The restored objective reflects the recovered autumn ledger.")
		"resume":
			_check_third_chapter("BackYard")
			_damage_save("user://investigation.json")
		"backup":
			_check_third_chapter("Room102")
			var hud := current_scene.get_node("InvestigationHud")
			_tap(hud.get_node("PauseButton"))
			await _settle()
			_tap(hud.get_node("PauseMenu/%ReturnButton"))
			await _settle()
			_check(current_scene.name == &"MainMenu" and not paused, "Return opens the active main menu.")
			_tap(current_scene.get_node("%NewGameButton"))
			await _settle()
			_tap(current_scene.get_node("%ConfirmButton"))
			await _settle()
			_check_fresh_game()
			_check(not FileAccess.file_exists("user://investigation.bak"), "Restart removes the previous game's backup.")
		"reset":
			_check_fresh_game()
			_damage_save("user://investigation.json")
			_damage_save("user://investigation.bak")
		"damaged":
			_check_fresh_game()
			_check(JSON.parse_string(FileAccess.get_file_as_string("user://investigation.json")) is Dictionary,
				"An explicit overwrite replaces the unreadable file with a playable save.")
		_:
			_check(false, "Expected a first/second/third, recovery, appointment, or final-review phase.")
	print("Autosave failures: ", _failures)
	quit(int(_failures > 0))


func _enter_from_menu(phase: String) -> bool:
	change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	await _settle()
	var menu := current_scene
	if menu == null or menu.name != &"MainMenu":
		_check(false, "The game launches into the main menu.")
		return false
	var can_continue := phase not in ["first", "damaged"]
	var continue_button := menu.get_node("%ContinueButton") as Button
	_check(continue_button.visible == can_continue, "Continue appears only for a playable save.")
	if phase == "first":
		_check(not FileAccess.file_exists("user://investigation.json"), "Opening the menu does not start an autosave.")
	if phase == "backup":
		_check(menu.get_node("%Notice").text.contains("上一份可用存档"), "The menu identifies backup recovery.")
	if phase == "damaged":
		_check(menu.get_node("%Notice").text.contains("未能读取存档"), "The menu identifies unreadable data.")
	var button := continue_button if can_continue else menu.get_node("%NewGameButton") as Button
	_tap(button)
	await _settle()
	if phase == "damaged":
		_check(current_scene == menu and FileAccess.get_file_as_string("user://investigation.json") == "{interrupted",
			"An unreadable save is preserved until the player confirms overwriting it.")
		_tap(menu.get_node("%ConfirmButton"))
		await _settle()
	var entered := current_scene != null and current_scene.has_node("InvestigationHud")
	_check(entered, "The main menu starts an investigation.")
	return entered


func _save_first_chapter() -> void:
	_check_fresh_game()
	_one.accept_commission()
	_log.record(_one.AUTHORIZATION)
	_one.inspect_seal()
	_log.record(_one.CART_SHEET)
	_transition.change_room("res://rooms/room_102.tscn", &"FromYard")
	await _settle()
	_one.finish_reenactment_step()
	_one.finish_reenactment_step()
	await _settle()
	_check(FileAccess.file_exists("user://investigation.json"), "A completed step creates the autosave.")
	var hud := current_scene.get_node("InvestigationHud")
	_tap(hud.get_node("PauseButton"))
	await _settle()
	var pause_menu := hud.get_node("PauseMenu")
	var save_button := pause_menu.get_node("%SaveButton") as Button
	var status := pause_menu.get_node("%Status") as Label
	var temporary := "user://investigation.json.tmp"
	_check(DirAccess.make_dir_absolute(temporary) == OK, "Simulate a storage write failure.")
	_tap(save_button)
	await _settle()
	_check(status.text.contains("保存失败") and paused, "A failed manual save is reported while paused.")
	_tap(pause_menu.get_node("%ReturnButton"))
	await _settle()
	_check(current_scene.name == &"Room102" and paused, "A failed save leaves the player in the room.")
	_check(DirAccess.remove_absolute(temporary) == OK, "Restore access to save storage.")
	_tap(save_button)
	await _settle()
	_check(status.text.begins_with("已保存"), "Manual save reports success after writing.")
	_tap(pause_menu.get_node("%ReturnButton"))
	await _settle()
	_check(current_scene.name == &"MainMenu" and not paused, "A saved investigation returns to the menu.")
	_tap(current_scene.get_node("%ContinueButton"))
	await _settle()
	_check(current_scene.name == &"Room102" and _one.reenactment_stage == _one.ReenactmentStage.SECOND_PASS,
		"Continuing in the same application restores the saved investigation.")


func _resume_first_and_save_second() -> void:
	_check(current_scene.name == &"Room102", "Resume in room 102.")
	if current_scene.name != &"Room102":
		return
	_check(_log.has_entry(_one.COMMISSION.id) and _log.has_entry(_one.EQUIPMENT_NOTE.id), "Both notes from accepting the commission survive.")
	_check(_one.reenactment_stage == _one.ReenactmentStage.SECOND_PASS, "Continue from the completed pad installation.")
	_check(not current_scene.get_node("Scenery/FootPad").visible, "Restoring progress updates the room before it appears.")
	_check(current_scene.get_node("WalkableFloor/DepthSort/LinHe").global_position.is_equal_approx(
		current_scene.get_node("Entrances/FromYard").global_position), "Use the room's saved entrance.")
	_one.finish_reenactment_step()
	_one.submit_reasoning(_one.RouteAnswer.FRONT_DOOR, _one.SoundAnswer.WHEEL)
	_one.submit_reasoning(_one.RouteAnswer.SUPPLY_DOOR, _one.SoundAnswer.STOOL_FOOT)
	_one.open_drawer()
	_one.pack_archive()
	_one.photograph_archive()
	_one.sign_inventory()
	_one.finish_chapter()
	_transition.start_chapter_two()
	await _settle()
	for entry in [_two.PHOTO, _two.FORWARDED_CROP, _two.RECEIPT, _two.PHOTO_CALL, _two.FILE_POCKET, _two.TRACKS, _two.ARCHIVE]:
		_log.record(entry)
	_two.submit_reasoning(_two.OrderAnswer.PHOTOGRAPHED_FIRST, _two.CandidatePage.MIDDLE)
	_check(_two.archive_and_withdraw_photo(), "Withdraw the original and retain its excerpt.")
	await _settle()


func _resume_second_and_save_third() -> void:
	_check(current_scene.name == &"FrontDesk" and _two.active and not _three.active, "Resume Friday at the front desk.")
	_check(_log.has_entry(&"chapter_one_attempt_0_1"), "Generated reasoning notes survive the process restart.")
	_check(_two.has_withdrawn_photo() and not _log.has_entry(_two.PHOTO.id) and not _log.has_entry(_two.FORWARDED_CROP.id),
		"Restoring the notebook preserves the photo withdrawal.")
	var entries: Array = _log.entries()
	_check(not entries.is_empty() and entries.back().preview != null, "The retained excerpt still has a scene preview.")
	_log.record(_two.HANDOVER_NOTICE)
	_log.record(_two.ACCIDENT_NOTICE)
	_two.finish_night_patrol()
	_transition.start_chapter_three()
	await _settle()
	_log.record(_three.COMMISSION)
	_log.record(_three.HIGH_WINDOW)
	_log.record(_three.SUPPLY_ACCESS)
	_transition.change_room("res://rooms/room_102.tscn", &"FromYard")
	await _settle()
	_log.record(_three.DESK_VIEW)
	await _settle()
	_transition.change_room("res://rooms/back_yard.tscn", &"FromRoom102")
	await _settle()
	# 1.0.16 wrote the same checkpoint fields except for the new appointment flag.
	var checkpoint: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://investigation.json"))
	checkpoint.erase("appointment_started")
	var file := FileAccess.open("user://investigation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(checkpoint))
	file.close()


func _resume_legacy_saturday_and_plan_appointment() -> void:
	_check_third_chapter("BackYard")
	_check(not _three.appointment_started, "A 1.0.16 checkpoint defaults to the 17:50 investigation.")
	_check(_three.submit_location(_three.Location.SHELTER).is_empty(), "The legacy checkpoint can proceed past the observation.")
	for entry in [_three.MESSAGE, _three.LOAN_CARD, _three.RETURN_NOTICE, _three.CALL, _three.DUTY_BOARD]:
		_log.record(entry)
	_transition.change_room("res://rooms/front_desk.tscn", &"FromCorridor")
	await _settle()


func _check_third_chapter(room: String) -> void:
	_check(current_scene.name == room and _three.active, "Resume Saturday at " + room + ".")
	_check(_three.can_submit_location() and _three.observation_pair().size() == 2,
		"Both observation views and the next deduction are available.")


func _check_fresh_game() -> void:
	_check(current_scene.name == &"FrontDesk" and _log.entries().is_empty() and not _one.commission_accepted
		and not _two.active and not _three.active, "Start at the front desk with no previous progress.")


func _damage_save(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	_check(file != null, "Can simulate a damaged save.")
	if file != null:
		file.store_string("{interrupted")
		file.close()


func _tap(button: Button) -> void:
	var position := button.get_global_transform_with_canvas() * (button.size * 0.5)
	for pressed in [true, false]:
		var touch := InputEventScreenTouch.new()
		touch.position = position
		touch.pressed = pressed
		root.push_input(touch, true)


func _settle() -> void:
	for frame in range(3):
		await process_frame


func _check(ok: bool, message: String) -> void:
	if not ok:
		_failures += 1
		push_error(message)
