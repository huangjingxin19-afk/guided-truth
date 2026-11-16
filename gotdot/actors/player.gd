extends CharacterBody2D

const MIN_ANIMATED_SPEED := 1.0
const DIAGONAL_TOLERANCE := 0.12
# At the source rate, a roughly 40 px side step takes two 150 ms frames.
const WALK_ANIMATION_REFERENCE_SPEED := 40.0 / 0.3

@export var walk_speed: float = 220.0

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var _sprite: AnimatedSprite2D = $Sprite

var _following_path := false
var _move_direction := Vector2.ZERO
var _facing := "front"


func walk_to(destination: Vector2) -> void:
	_move_direction = Vector2.ZERO
	navigation_agent.target_position = destination
	_following_path = true


func stop_walking() -> void:
	_following_path = false
	_move_direction = Vector2.ZERO
	velocity = Vector2.ZERO
	_show_standing()


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

	move_and_slide()
	_update_animation(get_real_velocity())


func _update_animation(motion: Vector2) -> void:
	var speed := motion.length()
	if speed < MIN_ANIMATED_SPEED:
		_show_standing()
		return

	var horizontal := absf(motion.x)
	var vertical := absf(motion.y)
	var face_sideways := horizontal > vertical
	# Keep the previous axis near a diagonal so joystick noise cannot flip it every tick.
	if absf(horizontal - vertical) <= DIAGONAL_TOLERANCE * maxf(horizontal, vertical):
		face_sideways = _facing == "left" or _facing == "right"

	if face_sideways:
		_facing = "right" if motion.x > 0.0 else "left"
	else:
		_facing = "front" if motion.y > 0.0 else "back"

	var playback_speed := maxf(speed / WALK_ANIMATION_REFERENCE_SPEED, 0.25)
	_sprite.play("walk_" + _facing, playback_speed)


func _show_standing() -> void:
	_sprite.animation = "idle_" + _facing
	_sprite.stop()
