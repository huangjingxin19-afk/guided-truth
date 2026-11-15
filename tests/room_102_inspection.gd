extends SceneTree

const ROOM_PATH := "res://rooms/room_102.tscn"
const FOOT_PAD_TOUCH := Vector2(551, 251)
const TRACKS_TOUCH := Vector2(627, 277)

var _failures := 0
var _player: CharacterBody2D
var _hud: CanvasLayer


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var room := (load(ROOM_PATH) as PackedScene).instantiate()
	root.add_child(room)
	_player = room.get_node("WalkableFloor/DepthSort/LinHe")
	_hud = room.get_node("InvestigationHud")
	var hint := room.get_node("Investigation/StandHint") as Line2D
	var floor_region := room.get_node("WalkableFloor") as NavigationRegion2D
	await _wait_for_inspection()

	await _expect_surrounding_stands(floor_region, "橡胶凳脚垫", FOOT_PAD_TOUCH, [
		Vector2(495, 251), Vector2(551, 244), Vector2(605, 251), Vector2(551, 320),
		Vector2(507, 244), Vector2(595, 244), Vector2(520, 317), Vector2(580, 317),
	])
	await _expect_surrounding_stands(floor_region, "地面轮痕", TRACKS_TOUCH, [
		Vector2(555, 257), Vector2(627, 244), Vector2(710, 302), Vector2(627, 318),
		Vector2(574, 244), Vector2(662, 260), Vector2(575, 292), Vector2(700, 337),
	])
	await _expect_evidence("橡胶凳脚垫", FOOT_PAD_TOUCH, Vector2(551, 325))
	await _expect_evidence("地面轮痕", TRACKS_TOUCH, Vector2(627, 325))
	await _expect_contextual_interaction()

	for point in [Vector2(581, 245), Vector2(674, 307), Vector2(635, 283)]:
		await _expect_evidence("地面轮痕", point, Vector2(627, 278))
	for point in [Vector2(534, 250), Vector2(551, 236), Vector2(570, 251), Vector2(551, 270)]:
		await _expect_evidence("橡胶凳脚垫", point, Vector2(551, 307))

	_player.global_position = Vector2(627, 318)
	_tap(Vector2(630, 240))
	await _wait_for_inspection()
	_check(not _hud.is_open() and not hint.visible, "Empty floor inside the button bounds is not a clue.")
	_player.stop_walking()

	_player.global_position = Vector2(551, 410)
	_tap(FOOT_PAD_TOUCH)
	await _wait_for_inspection()
	_check(not _hud.is_open() and hint.visible, "The foot pad is out of range from the front of the desk.")
	hint.hide()
	_tap(TRACKS_TOUCH)
	await _wait_for_inspection()
	_check(not _hud.is_open() and hint.visible, "The tracks are out of range from the front of the desk.")

	# Move the actual desk collision between the player and an otherwise nearby clue.
	var desk := room.get_node("WalkableFloor/DepthSort/LongDesk") as StaticBody2D
	desk.position = Vector2(368, 304)
	_player.global_position = Vector2(551, 312)
	await _wait_for_inspection()
	_check(not _hud.interaction_button.visible, "The desk hides the prompt even when the clue is within range.")
	hint.hide()
	_tap(FOOT_PAD_TOUCH)
	await _wait_for_inspection()
	_check(not _hud.is_open() and hint.visible, "A desk within inspection range still blocks the clue.")

	print("Inspection geometry failures: ", _failures)
	quit(int(_failures > 0))


func _expect_contextual_interaction() -> void:
	var action: Button = _hud.interaction_button
	_player.global_position = Vector2(307, 439)
	await _wait_for_inspection()
	_check(not action.visible, "No operation is shown far from clues.")
	_player.global_position = Vector2(555, 257)
	await _wait_for_inspection()
	_check(action.visible and action.text.ends_with("查看橡胶凳脚垫"), "The closer pad wins when both clues are reachable.")

	var joystick := _hud.get_node("TouchJoystick") as Control
	joystick.show()
	var stick_center := _button_center(joystick)
	_touch(stick_center, true, 0)
	_check(joystick.is_engaged(), "The left finger engages the joystick.")
	_tap(_button_center(action), 1)
	await _wait_for_inspection()
	_check(_hud.is_open() and _hud.header.text == "橡胶凳脚垫", "A second finger can activate the nearby clue.")
	_check(not action.visible and not joystick.is_engaged(), "Opening a clue hides the prompt and releases the joystick.")
	_touch(stick_center, false, 0)
	_tap(_button_center(_hud.close_button))
	await _wait_for_inspection()
	_check(action.visible, "The prompt returns on closing the clue.")

	_tap(_button_center(action))
	_player.global_position = Vector2(627, 278)
	await _wait_for_inspection()
	_check(not _hud.is_open(), "A queued press cannot switch to a different target after leaving reach.")
	_check(action.visible and action.text.ends_with("查看地面轮痕"), "Walking closer to the tracks changes the operation.")
	var interact := InputEventKey.new()
	interact.physical_keycode = KEY_E
	interact.pressed = true
	root.push_input(interact, true)
	interact = InputEventKey.new()
	interact.physical_keycode = KEY_E
	root.push_input(interact, true)
	await _wait_for_inspection()
	_check(_hud.is_open() and _hud.header.text == "地面轮痕", "The E key activates the displayed clue.")
	_tap(_button_center(_hud.close_button))
	_player.stop_walking()


func _expect_surrounding_stands(
	region: NavigationRegion2D, title: String, touch: Vector2, positions: Array[Vector2]
) -> void:
	for position in positions:
		var navigable := NavigationServer2D.region_get_closest_point(region.get_rid(), position)
		_check(position.is_equal_approx(navigable), "Fixture position is navigable: %s" % position)
		await _expect_evidence(title, touch, position)


func _expect_evidence(title: String, touch: Vector2, feet: Vector2) -> void:
	_player.global_position = feet
	_tap(touch)
	await _wait_for_inspection()
	_check(
		_hud.is_open() and _hud.header.text == title,
		"%s opens from %s when tapped at %s" % [title, feet, touch]
	)
	if _hud.is_open():
		var close := _hud.close_button as Button
		_tap(close.get_global_transform_with_canvas() * (close.size * 0.5))
	_player.stop_walking()


func _wait_for_inspection() -> void:
	await physics_frame
	await physics_frame
	await process_frame


func _button_center(control: Control) -> Vector2:
	return control.get_global_transform_with_canvas() * (control.size * 0.5)


func _tap(point: Vector2, index := 0) -> void:
	_touch(point, true, index)
	_touch(point, false, index)


func _touch(point: Vector2, pressed: bool, index: int) -> void:
	var touch := InputEventScreenTouch.new()
	touch.position = point
	touch.pressed = pressed
	touch.index = index
	root.push_input(touch, true)


func _check(passed: bool, context: String) -> void:
	if not passed:
		_failures += 1
		push_error(context)
