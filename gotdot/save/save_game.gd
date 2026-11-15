extends Node
## Stores a completed investigation checkpoint for the normal game launch.

const EvidenceEntry = preload("res://investigation/evidence_entry.gd")
const VERSION := 1
const SAVE_PATH := "user://investigation.json"
const BACKUP_PATH := "user://investigation.bak"
const ROOMS := {
	"front_desk": "res://rooms/front_desk.tscn",
	"corridor": "res://rooms/corridor.tscn",
	"back_yard": "res://rooms/back_yard.tscn",
	"room_102": "res://rooms/room_102.tscn",
}

var _session_open := false
var _write_blocked := false
var _save_queued := false
var _reset_pending := false
var _room := ""
var _entrance := ""
var _last_saved_json := ""
var _evidence_by_id: Dictionary[String, EvidenceEntry] = {}


func _ready() -> void:
	InvestigationLog.entry_recorded.connect(_on_entry_recorded)
	ChapterOne.progress_changed.connect(_queue_save)
	ChapterTwo.progress_changed.connect(_queue_save)
	ChapterThree.progress_changed.connect(_queue_save)
	RoomTransition.room_entered.connect(_on_room_entered)


func open_session() -> String:
	if _session_open:
		return ""
	var notice := ""
	var loaded := _read_save(SAVE_PATH)
	if loaded.is_empty():
		loaded = _read_save(BACKUP_PATH)
		if loaded.has("state"):
			notice = "已从上一份可用存档继续调查。"
	if loaded.has("state") and _restore(loaded):
		_last_saved_json = loaded.json
	else:
		_write_blocked = FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(BACKUP_PATH)
		if _write_blocked:
			var reason := "此存档来自较新的游戏版本。" if loaded.has("newer") else "未能读取存档。"
			notice = reason + "\n已保留原文件。如要建立新存档，请在笔记中确认「重新开始」。"
		RoomTransition.restore_room(ROOMS.front_desk, &"Start", Callable())
	_session_open = true
	return notice


func _on_entry_recorded(_entry: EvidenceEntry) -> void:
	_queue_save()


func _on_room_entered(scene_path: String, entrance: StringName, new_game: bool) -> void:
	var room_id: Variant = ROOMS.find_key(scene_path)
	_room = "" if room_id == null else String(room_id)
	_entrance = String(entrance)
	if _session_open and new_game:
		_write_blocked = false
		_reset_pending = true
	_queue_save()


func _queue_save() -> void:
	if _session_open and not _write_blocked and not _save_queued and not RoomTransition.is_changing:
		_save_queued = true
		# A single interaction can update several entries and chapter flags.
		_flush_save.call_deferred()


func _flush_save() -> void:
	_save_queued = false
	if _room.is_empty() or RoomTransition.is_changing:
		return
	var snapshot := JSON.stringify(_snapshot())
	if not _reset_pending and snapshot == _last_saved_json:
		return
	var result := _write_checkpoint(snapshot)
	if result == OK:
		_last_saved_json = snapshot
		_reset_pending = false
	else:
		push_warning("Could not save investigation progress: " + error_string(result))


func _snapshot() -> Dictionary:
	var evidence: Array = []
	for entry in InvestigationLog.entries():
		if entry.resource_path.is_empty():
			evidence.append({"id": String(entry.id), "title": entry.title, "description": entry.description})
		else:
			evidence.append(String(entry.id))
	var chapter := 1
	if ChapterThree.active:
		chapter = 3
	elif ChapterTwo.active:
		chapter = 2
	return {
		"version": VERSION,
		"room": _room,
		"entrance": _entrance,
		"chapter": chapter,
		"commission_accepted": ChapterOne.commission_accepted,
		"corridor_visited": ChapterOne.corridor_visited,
		"reenactment": ChapterOne.ReenactmentStage.keys()[ChapterOne.reenactment_stage],
		"case": ChapterOne.CaseStage.keys()[ChapterOne.case_stage],
		"evidence": evidence,
	}


func _read_save(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var contents := file.get_as_text()
	file.close()
	var parser := JSON.new()
	if parser.parse(contents) != OK or not parser.data is Dictionary:
		return {}
	var state: Dictionary = parser.data
	var version: Variant = state.get("version")
	if (version is int or version is float) and version > VERSION:
		return {"newer": true}
	if version != VERSION:
		return {}
	if not state.get("room") is String or not state.get("entrance") is String:
		return {}
	if not state.get("commission_accepted") is bool or not state.get("corridor_visited") is bool:
		return {}
	# JSON numbers are parsed as floats, and array membership compares types.
	if state.get("chapter") not in [1.0, 2.0, 3.0] or not state.get("evidence") is Array:
		return {}
	if not ChapterOne.ReenactmentStage.has(state.get("reenactment")) or not ChapterOne.CaseStage.has(state.get("case")):
		return {}
	if state.chapter >= 2 and state.case != "COMPLETE":
		return {}

	var entries: Array[EvidenceEntry] = []
	var ids := {}
	for record in state.evidence:
		var entry := _decode_entry(record)
		if entry == null or ids.has(entry.id):
			return {}
		ids[entry.id] = true
		entries.append(entry)
	if state.chapter == 3 and not ids.has(ChapterTwo.NIGHT_MESSAGE.id):
		return {}
	return {"state": state, "entries": entries, "json": contents}


func _decode_entry(record: Variant) -> EvidenceEntry:
	if record is String:
		if _evidence_by_id.is_empty():
			for filename in ResourceLoader.list_directory("res://investigation"):
				if filename.ends_with(".tres"):
					var entry := load("res://investigation/" + filename) as EvidenceEntry
					if entry != null:
						_evidence_by_id[String(entry.id)] = entry
		return _evidence_by_id.get(record)
	if not record is Dictionary or not record.get("id") is String:
		return null
	if record.id.is_empty() or not record.get("title") is String or not record.get("description") is String:
		return null
	var entry := EvidenceEntry.new()
	entry.id = StringName(record.id)
	entry.title = record.title
	entry.description = record.description
	return entry


func _restore(loaded: Dictionary) -> bool:
	var state: Dictionary = loaded.state
	var apply_progress := _apply_progress.bind(state, loaded.entries)
	if ROOMS.has(state.room) and state.entrance.is_valid_identifier():
		if RoomTransition.restore_room(ROOMS[state.room], StringName(state.entrance), apply_progress):
			return true
	if state.chapter == 3:
		return RoomTransition.restore_room(ROOMS.corridor, &"Saturday", apply_progress)
	return RoomTransition.restore_room(ROOMS.front_desk, &"Start", apply_progress)


func _apply_progress(state: Dictionary, entries: Array[EvidenceEntry]) -> void:
	# Rooms read this state in _ready; do not replay evidence collection callbacks.
	InvestigationLog.restore_entries(entries)
	ChapterOne.commission_accepted = state.commission_accepted
	ChapterOne.corridor_visited = state.corridor_visited
	ChapterOne.reenactment_stage = ChapterOne.ReenactmentStage[state.reenactment]
	ChapterOne.case_stage = ChapterOne.CaseStage[state.case]
	ChapterTwo.active = state.chapter >= 2
	ChapterThree.active = state.chapter == 3


func _write_checkpoint(snapshot: String) -> Error:
	if _reset_pending:
		# After a successful restart, recovery must never bring back the previous game.
		if FileAccess.file_exists(BACKUP_PATH):
			var remove_result := DirAccess.remove_absolute(BACKUP_PATH)
			if remove_result != OK:
				return remove_result
	elif not _last_saved_json.is_empty():
		var backup_result := _write_file(BACKUP_PATH, _last_saved_json)
		if backup_result != OK:
			return backup_result
	return _write_file(SAVE_PATH, snapshot)


func _write_file(path: String, contents: String) -> Error:
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var written := file.store_string(contents)
	file.flush()
	var result := file.get_error()
	file.close()
	if not written:
		return ERR_FILE_CANT_WRITE
	if result != OK:
		return result
	return DirAccess.rename_absolute(temporary, path)
