extends Node

const EvidenceEntry = preload("res://investigation/evidence_entry.gd")
const InvestigationHud = preload("res://ui/investigation_hud.gd")
const InspectionPoint = preload("res://investigation/inspection_point.gd")

@export var hud: InvestigationHud
@export var walk_hint: Label
@export var stand_hint: Line2D

var _nearby_point: InspectionPoint
var _requested_point: InspectionPoint


func _ready() -> void:
	hud.interaction_requested.connect(_request_interaction)
	hud.overlay_changed.connect(_on_overlay_changed)
	_show_walk_hint()


func _physics_process(_delta: float) -> void:
	if hud.is_open():
		return
	var requested := _requested_point
	_requested_point = null
	if is_instance_valid(requested):
		requested.try_interact()
		if not is_inside_tree() or hud.is_open():
			return
	var best_distance := INF
	_nearby_point = null
	for child in get_children():
		var point := child as InspectionPoint
		if point == null:
			continue
		var distance := point.reachable_distance_squared()
		if distance < best_distance:
			best_distance = distance
			_nearby_point = point
	hud.set_interaction_prompt(_nearby_point.get_interaction_label() if _nearby_point != null else "")


func _request_interaction() -> void:
	_requested_point = _nearby_point


func _on_overlay_changed(open: bool) -> void:
	if open:
		_nearby_point = null
		_requested_point = null
		hud.set_interaction_prompt("")


func show_approach_hint(position: Vector2, message: String) -> void:
	if hud.is_open():
		return

	walk_hint.text = message
	stand_hint.global_position = position
	stand_hint.show()


func inspect(entry: EvidenceEntry, action_label := "", action := Callable()) -> void:
	if hud.is_open():
		return

	clear_approach_hint()
	InvestigationLog.record(entry)
	hud.show_evidence(entry, false, action_label, action)


func open_notebook() -> void:
	hud.show_notebook(InvestigationLog.entries())


func clear_approach_hint() -> void:
	_show_walk_hint()
	stand_hint.hide()


func _show_walk_hint() -> void:
	walk_hint.text = "拖动摇杆或点击地面移动" if hud.uses_touch_controls() else "点击地面移动"
