extends Control

signal finished

const PASS := &"pass"
const INSTALL := &"install"
const HANSU_GRIP_TEXTURE := preload("res://actors/hansu/actions/hansu_pushcart_right.png")

@onready var _animation: AnimationPlayer = $AnimationPlayer
@onready var _han_su_sprite: Sprite2D = $CroppedView/Cart/Chassis/HanSuSprite
@onready var _pad: Node2D = $CroppedView/Cart/Chassis/Stool/Pad
@onready var _stool: Node2D = $CroppedView/Cart/Chassis/Stool
@onready var _scratch: Line2D = $CroppedView/Cart/Chassis/Scratch
@onready var _wheel_impact: AudioStreamPlayer = $WheelImpact
@onready var _stool_scrape: AudioStreamPlayer = $StoolScrape

var _pad_installed := false
var _scratch_visible := false

@export var scrape_progress := 0.0:
	set(value):
		scrape_progress = value
		if is_node_ready():
			_apply_scrape()


func is_playing() -> bool:
	return _animation.is_playing()


func play_pass(with_pad: bool) -> void:
	_pad_installed = with_pad
	_scratch_visible = with_pad
	_pad.visible = with_pad
	scrape_progress = 0.0
	_play_from_start(PASS)


func play_installation() -> void:
	_scratch_visible = true
	_pad.show()
	scrape_progress = 0.0
	_play_from_start(INSTALL)


func _play_from_start(clip: StringName) -> void:
	_wheel_impact.stop()
	_stool_scrape.stop()
	_animation.stop()
	_han_su_sprite.texture = HANSU_GRIP_TEXTURE
	_animation.play(clip)
	_animation.advance(0.0)


func _apply_scrape() -> void:
	var slide := 0.0 if _pad_installed else scrape_progress
	_stool.position.x = slide * 20.0
	var scratch_length := 1.0 if _scratch_visible else scrape_progress
	_scratch.visible = scratch_length > 0.0
	_scratch.set_point_position(1, Vector2(102.0 + scratch_length * 20.0, -3.0))


func _on_wheel_impact() -> void:
	if _wheel_impact.stream != null:
		_wheel_impact.play()


func _on_stool_scrape() -> void:
	if not _pad_installed and _stool_scrape.stream != null:
		_stool_scrape.play()


func _on_animation_finished(_clip: StringName) -> void:
	_wheel_impact.stop()
	_stool_scrape.stop()
	_han_su_sprite.texture = HANSU_GRIP_TEXTURE
	finished.emit()
