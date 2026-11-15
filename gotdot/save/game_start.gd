extends Node

const EvidenceEntry = preload("res://investigation/evidence_entry.gd")


func _ready() -> void:
	_open_investigation.call_deferred()


func _open_investigation() -> void:
	var tree := get_tree()
	var notice := SaveGame.open_session()
	if notice.is_empty():
		return
	var hud := tree.current_scene.get_node_or_null("InvestigationHud")
	if hud != null:
		var message := EvidenceEntry.new()
		message.title = "存档提示"
		message.description = notice
		hud.show_evidence(message)
