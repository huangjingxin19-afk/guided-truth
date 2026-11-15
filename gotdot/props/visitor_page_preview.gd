extends Node2D

enum Corner { FOLDED, COFFEE, WATER }

@export var date_caption := "周四"
@export var corner := Corner.COFFEE


func _draw() -> void:
	var paper := Color("#e6d7b3")
	draw_rect(Rect2(2, 3, 82, 90), Color("#3a302a"))
	draw_rect(Rect2(0, 0, 82, 90), paper)
	draw_string(ThemeDB.fallback_font, Vector2(8, 25), date_caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#322e27"))
	# Only the heading and corner are exposed.
	draw_rect(Rect2(5, 34, 72, 27), Color("#49453e"))
	match corner:
		Corner.FOLDED:
			draw_colored_polygon(PackedVector2Array([Vector2(67, 90), Vector2(67, 75), Vector2(82, 90)]), Color("#a58a62"))
		Corner.COFFEE:
			draw_circle(Vector2(64, 74), 10, Color("#8d5131"))
			draw_circle(Vector2(60, 71), 8, paper)
		Corner.WATER:
			draw_circle(Vector2(65, 76), 8, Color("#aaa992"), false, 2)
