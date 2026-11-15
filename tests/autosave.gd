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
	change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	await _settle()
	if current_scene == null or not current_scene.has_node("InvestigationHud"):
		push_error("The game did not launch into an investigation room.")
		quit(1)
		return

	var args := OS.get_cmdline_user_args()
	match args[0] if args.size() == 1 else "":
		"first":
			await _save_first_chapter()
		"second":
			await _resume_first_and_save_second()
		"third":
			await _resume_second_and_save_third()
		"resume":
			_check_third_chapter("BackYard")
			_damage_save("user://investigation.json")
		"backup":
			_check_third_chapter("Room102")
			_check(current_scene.get_node("InvestigationHud").header.text == "存档提示", "The player is told that a backup was loaded.")
			_transition.start_new_game()
			await _settle()
			_check_fresh_game()
			_check(not FileAccess.file_exists("user://investigation.bak"), "Restart removes the previous game's backup.")
		"reset":
			_check_fresh_game()
			_damage_save("user://investigation.json")
			_damage_save("user://investigation.bak")
		"damaged":
			_check_fresh_game()
			_check(current_scene.get_node("InvestigationHud").header.text == "存档提示", "Unreadable saves show a notice.")
			_one.accept_commission()
			await _settle()
			_check(FileAccess.get_file_as_string("user://investigation.json") == "{interrupted",
				"An unreadable save is preserved until the player confirms a restart.")
		_:
			_check(false, "Expected one phase: first, second, third, resume, backup, reset, damaged.")
	print("Autosave failures: ", _failures)
	quit(int(_failures > 0))


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


func _settle() -> void:
	for frame in range(3):
		await process_frame


func _check(ok: bool, message: String) -> void:
	if not ok:
		_failures += 1
		push_error(message)
