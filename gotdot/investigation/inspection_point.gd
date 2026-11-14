extends Button

const EvidenceEntry = preload("res://investigation/evidence_entry.gd")

signal approach_requested(position: Vector2, message: String)
signal inspection_requested(entry: EvidenceEntry)

@export var investigator: Node2D
@export var stands: Array[Marker2D] = []
@export var evidence: EvidenceEntry
@export var inspection_distance: float = 42.0
@export var approach_hint := "走到地面标记处再查看"


func _ready() -> void:
	tooltip_text = evidence.title
	accessibility_name = evidence.title


func _on_pressed() -> void:
	var nearest_stand: Marker2D
	var nearest_distance := INF
	for stand in stands:
		var distance := investigator.global_position.distance_squared_to(stand.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_stand = stand

	if nearest_distance <= inspection_distance * inspection_distance:
		inspection_requested.emit(evidence)
	elif nearest_stand != null:
		approach_requested.emit(nearest_stand.global_position, approach_hint)
