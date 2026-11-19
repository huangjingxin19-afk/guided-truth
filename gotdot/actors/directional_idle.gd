extends Node2D

const TURN_RADIUS_SQUARED := 144.0 * 144.0
const MIN_OFFSET_SQUARED := 4.0 * 4.0
const DIAGONAL_TOLERANCE := 0.12

@export var face_target: Node2D
@export var left_frame: Texture2D
@export var right_frame: Texture2D
@export var back_frame: Texture2D

@onready var _sprite: Sprite2D = $Sprite
@onready var _front_frame: Texture2D = _sprite.texture


func _process(_delta: float) -> void:
	if not is_visible_in_tree() or not is_instance_valid(face_target):
		return

	var offset := face_target.global_position - global_position
	var distance_squared := offset.length_squared()
	if distance_squared < MIN_OFFSET_SQUARED or distance_squared > TURN_RADIUS_SQUARED:
		return

	var horizontal := absf(offset.x)
	var vertical := absf(offset.y)
	var face_sideways := horizontal > vertical
	# Keep the last axis near a diagonal so small movements do not flicker.
	if absf(horizontal - vertical) <= DIAGONAL_TOLERANCE * maxf(horizontal, vertical):
		face_sideways = _sprite.texture == left_frame or _sprite.texture == right_frame

	if face_sideways:
		_sprite.texture = right_frame if offset.x > 0.0 else left_frame
	else:
		_sprite.texture = _front_frame if offset.y > 0.0 else back_frame
