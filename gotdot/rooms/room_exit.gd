extends "res://investigation/inspection_point.gd"

@export_file("*.tscn") var destination: String
@export var entrance: StringName


func _ready() -> void:
	super()
	interaction_requested.connect(_travel)


func _travel() -> void:
	RoomTransition.change_room(destination, entrance)
