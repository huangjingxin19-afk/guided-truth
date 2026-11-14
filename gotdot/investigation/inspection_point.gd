extends Button

const EvidenceEntry = preload("res://investigation/evidence_entry.gd")

signal approach_requested(position: Vector2, message: String)
signal inspection_requested(entry: EvidenceEntry)
signal interaction_requested

@export var investigator: CharacterBody2D
@export var target: Node2D
## Floor-plane outline in the target's local coordinates.
@export var target_outline: PackedVector2Array
@export var evidence: EvidenceEntry
@export var inspection_distance: float = 42.0
@export var touch_padding: float = 16.0
@export var hint_stands: Array[Marker2D] = []
@export var approach_hint := "走到地面标记处再查看"


func _ready() -> void:
	if evidence != null:
		tooltip_text = evidence.title
		accessibility_name = evidence.title
	set_physics_process(false)


func _has_point(point: Vector2) -> bool:
	if not Rect2(Vector2.ZERO, size).has_point(point):
		return false

	var world_point := get_global_transform() * point
	var nearest := _closest_target_point(world_point)
	return world_point.distance_squared_to(nearest) <= touch_padding * touch_padding


func _on_pressed() -> void:
	# Check furniture collisions during the next physics tick.
	set_physics_process(true)


func _physics_process(_delta: float) -> void:
	set_physics_process(false)
	var feet := investigator.global_position
	var nearest := _closest_target_point(feet)
	var in_range := feet.distance_squared_to(nearest) <= inspection_distance * inspection_distance
	if in_range and _has_clear_reach(feet, nearest):
		if evidence != null:
			inspection_requested.emit(evidence)
		else:
			interaction_requested.emit()
		return

	var nearest_stand: Marker2D
	var nearest_distance := INF
	for stand in hint_stands:
		var distance := feet.distance_squared_to(stand.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_stand = stand
	if nearest_stand != null:
		approach_requested.emit(nearest_stand.global_position, approach_hint)


func _closest_target_point(point: Vector2) -> Vector2:
	if not is_instance_valid(target) or target_outline.size() < 3:
		return Vector2.INF

	var outline := target.global_transform * target_outline
	if Geometry2D.is_point_in_polygon(point, outline):
		return point

	var nearest := Vector2.INF
	var nearest_distance := INF
	var start := outline[-1]
	for end in outline:
		var edge_point := Geometry2D.get_closest_point_to_segment(point, start, end)
		var distance := point.distance_squared_to(edge_point)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = edge_point
		start = end
	return nearest


func _has_clear_reach(from: Vector2, to: Vector2) -> bool:
	if from.is_equal_approx(to):
		return true

	var query := PhysicsRayQueryParameters2D.create(
		from, to, investigator.collision_mask, [investigator.get_rid()]
	)
	query.hit_from_inside = true
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()
