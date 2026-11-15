extends Node
## The only room-switching entry point. Exits supply a scene and entrance name.

const FRONT_DESK := "res://rooms/front_desk.tscn"
const CORRIDOR := "res://rooms/corridor.tscn"

var is_changing := false


func change_room(scene_path: String, entrance: StringName) -> void:
	_request_room_change(scene_path, entrance)


func start_new_game() -> void:
	_request_room_change(FRONT_DESK, &"Start", _reset_investigation)


func start_chapter_two() -> void:
	if ChapterTwo.can_start():
		_request_room_change(FRONT_DESK, &"Start", ChapterTwo.start)


func start_chapter_three() -> void:
	if ChapterThree.can_start():
		_request_room_change(CORRIDOR, &"Saturday", ChapterThree.start)


func _request_room_change(scene_path: String, entrance: StringName, on_enter := Callable()) -> void:
	if is_changing:
		return
	is_changing = true
	_change_room.call_deferred(scene_path, entrance, on_enter)


func _change_room(scene_path: String, entrance: StringName, on_enter: Callable) -> void:
	var scene := load(scene_path) as PackedScene
	if scene == null:
		push_error("Cannot load room: " + scene_path)
		is_changing = false
		return
	# Validate the destination before removing the current room or clearing the log.
	var room := scene.instantiate()
	var marker := room.get_node_or_null("Entrances/" + String(entrance)) as Marker2D
	var player := room.get_node_or_null("WalkableFloor/DepthSort/LinHe") as CharacterBody2D
	if marker == null or player == null:
		push_error("Room is missing its player or entrance: " + scene_path)
		room.free()
		is_changing = false
		return
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


func _reset_investigation() -> void:
	InvestigationLog.reset()
	ChapterThree.reset()
	ChapterTwo.reset()
	ChapterOne.reset()
