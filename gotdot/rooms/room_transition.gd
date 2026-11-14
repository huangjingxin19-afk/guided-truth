extends Node
## The only room-switching entry point. Exits supply a scene and entrance name.

const FRONT_DESK := "res://rooms/front_desk.tscn"

var is_changing := false


func change_room(scene_path: String, entrance: StringName) -> void:
	if is_changing:
		return
	is_changing = true
	_change_room.call_deferred(scene_path, entrance, false)


func start_new_game() -> void:
	if is_changing:
		return
	is_changing = true
	_change_room.call_deferred(FRONT_DESK, &"Start", true)


func _change_room(scene_path: String, entrance: StringName, new_game: bool) -> void:
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
	if new_game:
		InvestigationLog.reset()
		ChapterOne.reset()
	get_tree().root.add_child(room)
	get_tree().current_scene = room
	player.global_position = marker.global_position
	is_changing = false
