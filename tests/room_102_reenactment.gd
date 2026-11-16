extends SceneTree

const ThresholdReenactment = preload("res://rooms/room_102_threshold_reenactment.gd")
const REENACTMENT_ID := &"room102_cart_reenactment"

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var room := (load("res://rooms/room_102.tscn") as PackedScene).instantiate()
	root.add_child(room)
	var player := room.get_node("WalkableFloor/DepthSort/LinHe") as CharacterBody2D
	var hud := room.get_node("InvestigationHud") as CanvasLayer
	var reenactment := room.get_node("ThresholdReenactment") as ThresholdReenactment
	var animation := reenactment.get_node("AnimationPlayer") as AnimationPlayer
	var han_su_sprite := reenactment.get_node("CroppedView/Cart/Chassis/HanSuSprite") as Sprite2D
	var wheel := reenactment.get_node("WheelImpact") as AudioStreamPlayer
	var scrape := reenactment.get_node("StoolScrape") as AudioStreamPlayer
	var stool := reenactment.get_node("CroppedView/Cart/Chassis/Stool") as Node2D
	var pad := stool.get_node("Pad") as Node2D
	var scratch := reenactment.get_node("CroppedView/Cart/Chassis/Scratch") as Line2D
	var han_su := room.get_node("Investigation/HanSuPoint") as Button
	var foot_pad := room.get_node("Scenery/FootPad") as Node2D
	var foot_pad_point := room.get_node("Investigation/FootPadPoint") as Button
	var log := root.get_node("InvestigationLog")

	await _inspect(han_su)
	_check(not hud.is_open(), "Han Su cannot be triggered from across the room.")
	player.global_position = Vector2(503, 280)
	await _inspect(foot_pad_point)
	_check(hud.is_open() and not hud.evidence_action_button.visible, "Early inspection cannot install the pad.")
	_press_escape()
	_check(not hud.is_open() and not paused, "Escape closes an open evidence page before pausing.")

	wheel.stream = _temporary_stream()
	scrape.stream = _temporary_stream()
	player.global_position = Vector2(722, 286)
	await _wait_for_input()
	_check(hud.interaction_button.text.ends_with("看推车过门槛"), "The shared button offers the first pass near Han Su.")
	await _inspect(hud.interaction_button)
	_check(hud.header.text == "第一次过门槛" and not hud.close_button.visible, "First pass opens a locked presentation.")
	_check(_entry_count(log) == 0 and not pad.visible and not scratch.visible, "First pass starts with a bare leg and no scratch.")
	_tap_button(hud.get_node("PauseButton"))
	var animation_position := animation.current_animation_position
	await create_timer(0.12).timeout
	_check(paused and not animation.can_process() and is_equal_approx(animation.current_animation_position, animation_position),
		"Pausing freezes the moving cart and the animation clock.")
	hud.get_node("PauseMenu").notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_check(not paused and animation.can_process() and hud.overlay.visible,
		"Android Back resumes the same reenactment.")
	await _advance(animation, 0.73)
	_check(wheel.playing and not scrape.playing, "First front wheel plays the impact only.")
	wheel.stop()
	await _advance(animation, 0.29)
	_check(not wheel.playing and scrape.playing, "First pass plays the scrape between impacts.")
	_check(stool.position.x > 0.0 and scratch.visible, "The bare leg slides and shows a scratch.")
	await _advance(animation, 0.31)
	_check(wheel.playing, "First rear wheel plays the same impact.")
	await _advance(animation, 2.4)
	_check(not hud.is_open() and not han_su.visible and foot_pad.visible, "First pass returns to the pad investigation.")

	await _inspect(hud.get_node("NotebookButton"))
	var note := hud.notebook_list.get_child(0) as Button
	_tap_button(note)
	_check(not hud.evidence_action_button.visible, "Notebook evidence is read-only.")
	_tap_button(hud.close_button)
	_tap_button(hud.close_button)

	player.global_position = Vector2(503, 280)
	await _wait_for_input()
	await _inspect(hud.interaction_button)
	_check(hud.evidence_action_button.visible, "Live pad inspection offers installation after the first pass.")
	_tap_button(hud.evidence_action_button)
	_check(animation.current_animation == "install" and foot_pad.visible, "Installation plays before removing the floor prop.")
	_check(han_su_sprite.texture.resource_path.ends_with("hansu_pushcart_right.png"), "Han Su holds the static grip pose while installing the pad.")
	await _advance(animation, 0.88)
	_check(pad.is_visible_in_tree() and pad.position.is_equal_approx(Vector2(102, 0)), "The pad fits onto the leg.")
	await _advance(animation, 1.45)
	_check(not hud.is_open() and not foot_pad.visible and not foot_pad_point.visible, "Installation removes the floor prop and its touch target.")
	_check(han_su.visible and han_su.text == "再推一次" and _entry_count(log) == 0, "Second pass is available before recording the result.")

	player.global_position = Vector2(722, 286)
	await _wait_for_input()
	_check(hud.interaction_button.text.ends_with("再推一次"), "The shared button picks up Han Su's new action.")
	await _inspect(hud.interaction_button)
	var watching_position := player.global_position
	_tap(Vector2(797, 400))
	await _advance(animation, 0.73)
	_check(player.global_position == watching_position, "The presentation consumes room movement taps.")
	_check(wheel.playing and not scrape.playing, "Second front wheel still plays the impact.")
	wheel.stop()
	await _advance(animation, 0.29)
	_check(not wheel.playing and not scrape.playing, "Second pass leaves the scrape audio slot idle.")
	_check(stool.position.x == 0.0 and pad.is_visible_in_tree() and scratch.visible, "The padded leg stays still beside the existing scratch.")
	_check(pad.position.is_equal_approx(Vector2(102, 0)), "The pad stays attached during the second pass.")
	await _advance(animation, 0.31)
	_check(wheel.playing, "Second rear wheel still plays the impact.")
	await _advance(animation, 2.4)
	_check(not hud.is_open() and not han_su.visible, "Completion returns control and closes the replay entry.")
	_check(not hud.interaction_button.text.ends_with("再推一次") or not hud.interaction_button.visible, "The completed replay is no longer an available action.")
	_check(_entry_count(log) == 1, "Completion records exactly one comparison.")
	_check(not wheel.playing and not scrape.playing, "Closing the presentation stops its audio.")

	# The shipping scene has empty Stream slots.
	wheel.stream = null
	scrape.stream = null
	reenactment.play_pass(false)
	await _advance(animation, 2.4)
	_check(not wheel.playing and not scrape.playing, "Empty streams allow the animation to finish.")

	reenactment.play_pass(false)
	animation.pause()
	animation.seek(0.82, true)
	_check(han_su_sprite.texture.resource_path.ends_with("hansu_pushcart_walk_right_02.png"),
		"Han Su's walking frame follows the reenactment animation clock.")
	animation.seek(1.13, true)
	_check(han_su_sprite.texture.resource_path.ends_with("hansu_pushcart_walk_right_04.png"),
		"Seeking the animation updates Han Su's walking frame.")
	animation.stop()

	# Let the audio mixer release the stopped test streams before exiting.
	await create_timer(0.1).timeout
	print("Cart reenactment failures: ", _failures)
	quit(int(_failures > 0))


func _temporary_stream() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.mix_rate = 8000
	var samples := PackedByteArray()
	samples.resize(8000)
	stream.data = samples
	return stream


func _advance(animation: AnimationPlayer, seconds: float) -> void:
	animation.advance(seconds)
	await process_frame


func _entry_count(log: Node) -> int:
	var count := 0
	for entry in log.entries():
		if entry.id == REENACTMENT_ID:
			count += 1
	return count


func _inspect(button: Button) -> void:
	_tap_button(button)
	await _wait_for_input()


func _wait_for_input() -> void:
	await physics_frame
	await physics_frame
	await process_frame


func _press_escape() -> void:
	for pressed in [true, false]:
		var key := InputEventKey.new()
		key.keycode = KEY_ESCAPE
		key.pressed = pressed
		root.push_input(key, true)


func _tap_button(button: Button) -> void:
	_tap(button.get_global_transform_with_canvas() * (button.size * 0.5))


func _tap(at: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.position = at
	event.pressed = true
	root.push_input(event, true)
	event = InputEventScreenTouch.new()
	event.position = at
	root.push_input(event, true)


func _check(passed: bool, description: String) -> void:
	if not passed:
		_failures += 1
		push_error(description)
