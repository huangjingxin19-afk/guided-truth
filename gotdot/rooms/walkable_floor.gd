extends NavigationRegion2D

const Player = preload("res://actors/player.gd")
const FLOOR_POINT_TOLERANCE := 0.5

@export var player: Player
@export var boundary: CollisionPolygon2D

var _overlay_open := false
var _steering := false


func _ready() -> void:
	# Use the collision outline as the walkable area and bake furniture as obstructions.
	var boundary_to_region := global_transform.affine_inverse() * boundary.global_transform
	navigation_polygon.clear_outlines()
	navigation_polygon.add_outline(boundary_to_region * boundary.polygon)
	bake_navigation_polygon(false)


func set_overlay_open(open: bool) -> void:
	_overlay_open = open
	if open:
		player.stop_walking()


func steer(direction: Vector2, engaged: bool) -> void:
	_steering = engaged
	if not _overlay_open:
		player.set_move_direction(direction)


func _input(event: InputEvent) -> void:
	# Room controls use native touch. Notebook scrolling still relies on mouse emulation.
	if not _overlay_open and event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if _overlay_open or _steering or DisplayServer.is_touchscreen_available():
		return

	var pointer_position: Vector2
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pointer_position = event.position
	elif event is InputEventScreenTouch and event.pressed and not event.canceled:
		pointer_position = event.position
	else:
		return

	var region := get_rid()
	if NavigationServer2D.region_get_iteration_id(region) == 0:
		return

	var destination := get_canvas_transform().affine_inverse() * pointer_position
	var nearest := NavigationServer2D.region_get_closest_point(region, destination)
	if destination.distance_squared_to(nearest) > FLOOR_POINT_TOLERANCE * FLOOR_POINT_TOLERANCE:
		return

	player.walk_to(nearest)
	get_viewport().set_input_as_handled()
