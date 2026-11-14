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
	hint.hide()
	_tap(FOOT_PAD_TOUCH)
	await _wait_for_inspection()
	_check(not _hud.is_open() and hint.visible, "A desk within inspection range still blocks the clue.")

	print("Inspection geometry failures: ", _failures)
	quit(int(_failures > 0))


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


func _tap(point: Vector2) -> void:
	var press := InputEventScreenTouch.new()
	press.position = point
	press.pressed = true
	root.push_input(press, true)
	var release := InputEventScreenTouch.new()
	release.position = point
	root.push_input(release, true)


func _check(passed: bool, context: String) -> void:
	if not passed:
		_failures += 1
		push_error(context)
