extends Node2D

const InvestigationHud = preload("res://ui/investigation_hud.gd")
const Player = preload("res://actors/player.gd")
const FOOT_PAD = preload("res://investigation/foot_pad.tres")
const INSPECTION_DISTANCE := 42.0

@onready var walkable_floor: NavigationRegion2D = $WalkableFloor
@onready var player: Player = $WalkableFloor/DepthSort/LinHe
@onready var foot_pad_stand: Marker2D = $FootPadStand
@onready var stand_hint: Line2D = $FootPadStand/StandHint
@onready var walk_hint: Label = $WalkHint
@onready var hud: InvestigationHud = $InvestigationHud


func _ready() -> void:
	# Bake the floor outline together with the furniture's collision shapes.
	walkable_floor.bake_navigation_polygon(false)


func _unhandled_input(event: InputEvent) -> void:
	if hud.is_open() or not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	if NavigationServer2D.region_get_iteration_id(walkable_floor.get_rid()) == 0:
		return

	var destination: Vector2 = get_canvas_transform().affine_inverse() * event.position
	var nearest := NavigationServer2D.region_get_closest_point(walkable_floor.get_rid(), destination)
	if destination.distance_squared_to(nearest) > 0.25:
		return

	player.walk_to(nearest)
	get_viewport().set_input_as_handled()


func _on_foot_pad_pressed() -> void:
	if hud.is_open():
		return
	if player.global_position.distance_to(foot_pad_stand.global_position) > INSPECTION_DISTANCE:
		walk_hint.text = "走到桌后的地面标记，再点脚垫"
		stand_hint.show()
		return

	walk_hint.text = "点击地面移动"
	stand_hint.hide()
	player.stop_walking()
	InvestigationLog.record(FOOT_PAD)
	hud.show_evidence(FOOT_PAD)


func _on_notebook_requested() -> void:
	player.stop_walking()
	hud.show_notebook(InvestigationLog.entries())
