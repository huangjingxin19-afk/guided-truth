extends Node
## The only room-switching entry point. Exits supply a scene and entrance name.

const FRONT_DESK := "res://rooms/front_desk.tscn"
const CORRIDOR := "res://rooms/corridor.tscn"
const ROOM_102 := "res://rooms/room_102.tscn"

signal room_entered(scene_path: String, entrance: StringName)

var is_changing := false


func change_room(scene_path: String, entrance: StringName) -> void:
	_request_room_change(scene_path, entrance)


func start_new_game() -> bool:
	return restore_room(FRONT_DESK, &"Start", _reset_investigation)


func start_chapter_two() -> void:
	if ChapterTwo.can_start():
		_request_room_change(FRONT_DESK, &"Start", ChapterTwo.start)


func start_chapter_three() -> void:
	if ChapterThree.can_start():
		_request_room_change(CORRIDOR, &"Saturday", ChapterThree.start)


func start_saturday_appointment() -> void:
	if ChapterThree.can_confirm_appointment():
		_request_room_change(ROOM_102, &"FromYard", ChapterThree.start_appointment)


func restore_room(scene_path: String, entrance: StringName, restore_progress: Callable) -> bool:
	if is_changing:
		return false
	is_changing = true
	return _change_room(scene_path, entrance, restore_progress)


func _request_room_change(scene_path: String, entrance: StringName, on_enter := Callable()) -> void:
	if is_changing:
		return
	is_changing = true
	_change_room.call_deferred(scene_path, entrance, on_enter)


func _change_room(scene_path: String, entrance: StringName, on_enter: Callable) -> bool:
	var scene := load(scene_path) as PackedScene
	if scene == null:
		push_error("Cannot load room: " + scene_path)
		is_changing = false
		return false
	# Validate the destination before removing the current room or clearing the log.
	var room := scene.instantiate()
	var marker := room.get_node_or_null("Entrances/" + String(entrance)) as Marker2D
	var player := room.get_node_or_null("WalkableFloor/DepthSort/LinHe") as CharacterBody2D
	if marker == null or player == null:
		push_error("Room is missing its player or entrance: " + scene_path)
		room.free()
		is_changing = false
		return false
	var previous := get_tree().current_scene
	if previous != null:
		get_tree().root.remove_child(previous)
		previous.queue_free()
	if on_enter.is_valid():
		on_enter.call()
	get_tree().root.add_child(room)
	get_tree().current_scene = room
	player.global_position = marker.global_position
	is_changing = false
	room_entered.emit(scene_path, entrance)
	return true


func _reset_investigation() -> void:
	InvestigationLog.reset()
	ChapterThree.reset()
	ChapterTwo.reset()
	ChapterOne.reset()
