extends CharacterBody2D

@export var walk_speed: float = 220.0

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var facing: Node2D = $Facing

var walking := false


func walk_to(destination: Vector2) -> void:
	navigation_agent.target_position = destination
	walking = true


func stop_walking() -> void:
	walking = false
	velocity = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if not walking:
		return

	var next_point := navigation_agent.get_next_path_position()
	if navigation_agent.is_navigation_finished():
		stop_walking()
		return

	var offset := next_point - global_position
	velocity = offset.limit_length(walk_speed * delta) / delta
	if absf(velocity.x) > 1.0:
		facing.scale.x = signf(velocity.x)
	move_and_slide()
