extends CharacterBody2D

@export var walk_speed: float = 220.0

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var facing: Node2D = $Facing

var _following_path := false
var _move_direction := Vector2.ZERO


func walk_to(destination: Vector2) -> void:
	_move_direction = Vector2.ZERO
	navigation_agent.target_position = destination
	_following_path = true


func stop_walking() -> void:
	_following_path = false
	_move_direction = Vector2.ZERO
	velocity = Vector2.ZERO


func set_move_direction(direction: Vector2) -> void:
	if direction.is_zero_approx():
		stop_walking()
		return

	_following_path = false
	_move_direction = direction


func _physics_process(delta: float) -> void:
	if not _move_direction.is_zero_approx():
		velocity = _move_direction * walk_speed
	elif _following_path:
		var next_point := navigation_agent.get_next_path_position()
		if navigation_agent.is_navigation_finished():
			stop_walking()
			return
		var offset := next_point - global_position
		velocity = offset.limit_length(walk_speed * delta) / delta
	else:
		return

	if absf(velocity.x) > 1.0:
		facing.scale.x = signf(velocity.x)
	move_and_slide()
