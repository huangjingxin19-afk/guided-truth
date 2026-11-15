extends "res://investigation/inspection_point.gd"

signal travel_blocked

@export_file("*.tscn") var destination: String
@export var entrance: StringName

var travel_allowed := true


func _ready() -> void:
	super()
	interaction_requested.connect(_travel)


func _travel() -> void:
	if travel_allowed:
		RoomTransition.change_room(destination, entrance)
	else:
		travel_blocked.emit()
