extends Button

const EvidenceEntry = preload("res://investigation/evidence_entry.gd")

signal approach_requested(position: Vector2, message: String)
signal inspection_requested(entry: EvidenceEntry)

@export var investigator: Node2D
@export var stand: Marker2D
@export var evidence: EvidenceEntry
@export var inspection_distance: float = 42.0
@export var approach_hint := "走到地面标记处再查看"


func _ready() -> void:
	tooltip_text = evidence.title
	accessibility_name = evidence.title


func _on_pressed() -> void:
	if investigator.global_position.distance_to(stand.global_position) > inspection_distance:
		approach_requested.emit(stand.global_position, approach_hint)
		return

	inspection_requested.emit(evidence)
