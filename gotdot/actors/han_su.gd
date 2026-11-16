extends Node2D

enum Pose { FRONT, LEFT, RIGHT, BACK, GRIP }

const TEXTURES := [
	preload("res://actors/hansu/idle/hansu_idle_front.png"),
	preload("res://actors/hansu/idle/hansu_idle_left.png"),
	preload("res://actors/hansu/idle/hansu_idle_right.png"),
	preload("res://actors/hansu/idle/hansu_idle_back.png"),
	preload("res://actors/hansu/actions/hansu_pushcart_right.png"),
]

@export var pose := Pose.FRONT:
	set(value):
		pose = value
		if is_node_ready():
			$Sprite.texture = TEXTURES[pose]


func _ready() -> void:
	$Sprite.texture = TEXTURES[pose]
