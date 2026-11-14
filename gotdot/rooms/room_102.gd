extends Node2D

const InvestigationHud = preload("res://ui/investigation_hud.gd")
const FOOT_PAD = preload("res://investigation/foot_pad.tres")
const INSPECTION_DISTANCE := 42.0

@onready var player: Node2D = %LinHe
@onready var foot_pad_stand: Marker2D = $FootPadStand
@onready var stand_hint: Line2D = $FootPadStand/StandHint
@onready var walk_hint: Label = $WalkHint
@onready var hud: InvestigationHud = $InvestigationHud


func _ready() -> void:
	_show_walk_hint()


func _on_foot_pad_pressed() -> void:
	if hud.is_open():
		return
	if player.global_position.distance_to(foot_pad_stand.global_position) > INSPECTION_DISTANCE:
		walk_hint.text = "走到桌后的地面标记，再点脚垫"
		stand_hint.show()
		return

	_show_walk_hint()
	stand_hint.hide()
	InvestigationLog.record(FOOT_PAD)
	hud.show_evidence(FOOT_PAD)


func _on_notebook_requested() -> void:
	hud.show_notebook(InvestigationLog.entries())


func _show_walk_hint() -> void:
	walk_hint.text = "点击地面移动"
	if hud.uses_touch_controls():
		walk_hint.text = "拖动摇杆或点击地面移动"
