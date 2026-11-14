extends Control

signal movement_changed(direction: Vector2, engaged: bool)

const BASE_RADIUS := 54.0
const TRAVEL_RADIUS := 34.0
const DEAD_ZONE := 8.0
const THUMB_IDLE := Color(0.76, 0.74, 0.64, 0.78)
const THUMB_ENGAGED := Color(0.88, 0.82, 0.66, 0.92)

var _touch_index := -1
var _thumb_offset := Vector2.ZERO


func is_engaged() -> bool:
	return _touch_index != -1


func _has_point(point: Vector2) -> bool:
	return point.distance_to(size * 0.5) <= BASE_RADIUS


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.index == _touch_index and (not event.pressed or event.canceled):
			_release()
		elif event.pressed and not event.canceled and not is_engaged():
			_touch_index = event.index
			_update_thumb(event.position)
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_thumb(event.position)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			_release()
		NOTIFICATION_VISIBILITY_CHANGED:
			if not is_visible_in_tree():
				_release()


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, BASE_RADIUS, Color(0.08, 0.10, 0.10, 0.70), true, -1.0, true)
	draw_arc(center, BASE_RADIUS, 0, TAU, 64, Color(0.85, 0.81, 0.68, 0.62), 2.0, true)
	var thumb_color := THUMB_ENGAGED if is_engaged() else THUMB_IDLE
	draw_circle(center + _thumb_offset, 17.0, thumb_color, true, -1.0, true)


func _update_thumb(point: Vector2) -> void:
	_thumb_offset = (point - size * 0.5).limit_length(TRAVEL_RADIUS)
	var strength := clampf(inverse_lerp(DEAD_ZONE, TRAVEL_RADIUS, _thumb_offset.length()), 0.0, 1.0)
	movement_changed.emit(_thumb_offset.normalized() * strength, true)
	queue_redraw()


func _release() -> void:
	if not is_engaged():
		return
	_touch_index = -1
	_thumb_offset = Vector2.ZERO
	movement_changed.emit(Vector2.ZERO, false)
	queue_redraw()
