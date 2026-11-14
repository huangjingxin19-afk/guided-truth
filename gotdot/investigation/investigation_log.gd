extends Node

const EvidenceEntry = preload("res://investigation/evidence_entry.gd")

var _entries: Dictionary[StringName, EvidenceEntry] = {}


func record(entry: EvidenceEntry) -> void:
	if not _entries.has(entry.id):
		_entries[entry.id] = entry


func entries() -> Array[EvidenceEntry]:
	var recorded: Array[EvidenceEntry] = []
	recorded.assign(_entries.values())
	return recorded
