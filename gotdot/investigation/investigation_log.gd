extends Node

const EvidenceEntry = preload("res://investigation/evidence_entry.gd")

signal entry_recorded(entry: EvidenceEntry)

var _entries: Dictionary[StringName, EvidenceEntry] = {}


func reset() -> void:
	_entries.clear()


func has_entry(id: StringName) -> bool:
	return _entries.has(id)


func record(entry: EvidenceEntry) -> void:
	if not _entries.has(entry.id):
		_entries[entry.id] = entry
		entry_recorded.emit(entry)


func replace_with(entry: EvidenceEntry, superseded_ids: Array[StringName]) -> void:
	if has_entry(entry.id):
		return
	_entries[entry.id] = entry
	for id in superseded_ids:
		_entries.erase(id)
	entry_recorded.emit(entry)


func entries() -> Array[EvidenceEntry]:
	var recorded: Array[EvidenceEntry] = []
	recorded.assign(_entries.values())
	return recorded
