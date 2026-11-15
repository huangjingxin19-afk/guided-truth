extends Node2D
## Both observations share the same pose and shelter layout.

@export var from_desk := false


func _draw() -> void:
	draw_rect(Rect2(-116, -52, 232, 104), Color("#465452"))
	draw_rect(Rect2(-108, -43, 216, 61), Color("#68746a"))
	draw_rect(Rect2(-108, 14, 216, 30), Color("#506666"))
	draw_line(Vector2(-108, 14), Vector2(108, 14), Color("#84938a"), 2)
	draw_line(Vector2(-96, 37), Vector2(-62, 37), Color("#7b9997"), 2)
	draw_line(Vector2(68, 32), Vector2(96, 32), Color("#7b9997"), 2)
	draw_line(Vector2(36, 40), Vector2(62, 40), Color("#7b9997"), 2)

	# The bench and Zhou Wen occupy the same place in both views.
	draw_rect(Rect2(-60, 9, 90, 8), Color("#b99a6a"))
	draw_rect(Rect2(-60, 17, 90, 4), Color("#765d43"))
	draw_rect(Rect2(-56, 21, 5, 16), Color("#4c4338"))
	draw_rect(Rect2(21, 21, 5, 16), Color("#4c4338"))
	draw_colored_polygon(
		PackedVector2Array([Vector2(39, 7), Vector2(61, 8), Vector2(67, 38), Vector2(57, 38),
			Vector2(49, 23), Vector2(45, 38), Vector2(34, 38)]),
		Color("#2b353a")
	)
	draw_colored_polygon(
		PackedVector2Array([Vector2(31, -28), Vector2(47, -24), Vector2(59, -10),
			Vector2(63, 10), Vector2(39, 11), Vector2(29, -9), Vector2(19, -3), Vector2(10, -8)]),
		Color("#566d80")
	)
	draw_rect(Rect2(21, -43, 20, 18), Color("#c89977"))
	draw_rect(Rect2(20, -43, 22, 6), Color("#34302e"))
	draw_rect(Rect2(21, -36, 4, 8), Color("#a97e64"))
	draw_rect(Rect2(8, -10, 8, 7), Color("#c89977"))
	draw_rect(Rect2(1, -12, 10, 9), Color("#eabd58"))
	draw_line(Vector2(2, -6), Vector2(-34, 7), Color("#f1c865"), 3)
	for x in [-30, -22, -14, -6]:
		var y := -6.0 - float(x) * 0.36
		draw_line(Vector2(x, y - 1), Vector2(x, y + 1), Color("#665139"), 1)

	if from_desk:
		_draw_glass()
	else:
		_draw_high_window()


func _draw_glass() -> void:
	# The sill and near edge are in front of the figure and outside ground.
	draw_rect(Rect2(-108, -44, 216, 87), Color(0.54, 0.74, 0.73, 0.08))
	draw_rect(Rect2(-108, 43, 216, 7), Color("#2b3d40"))
	draw_line(Vector2(-104, 43), Vector2(107, 43), Color("#aac0b9"), 2)
	draw_rect(Rect2(-83, -47, 8, 96), Color("#293e41"))
	draw_line(Vector2(-75, -46), Vector2(-75, 43), Color("#aac0b9"), 2)
	draw_line(Vector2(-66, -31), Vector2(-49, -45), Color(0.8, 0.93, 0.9, 0.44), 2)
	draw_line(Vector2(-68, -23), Vector2(-55, -34), Color(0.8, 0.93, 0.9, 0.26), 2)
	draw_rect(Rect2(-116, -52, 8, 104), Color("#273538"))
	draw_rect(Rect2(108, -52, 8, 104), Color("#273538"))
	draw_rect(Rect2(-116, -52, 232, 5), Color("#273538"))


func _draw_high_window() -> void:
	draw_rect(Rect2(-108, -32, 22, 56), Color("#414944"))
	draw_rect(Rect2(-92, -21, 33, 25), Color("#596157"))
	draw_rect(Rect2(-105, -32, 43, 4), Color("#303b37"))
	draw_rect(Rect2(-101, 8, 212, 34), Color("#39423e"))
	draw_rect(Rect2(-103, 8, 215, 4), Color("#849082"))
	draw_rect(Rect2(-103, 23, 216, 4), Color("#282f2c"))
	draw_rect(Rect2(-112, -52, 11, 104), Color("#333f3f"))
	draw_rect(Rect2(101, -52, 15, 104), Color("#333f3f"))
	draw_rect(Rect2(-116, -52, 232, 6), Color("#333f3f"))
	draw_rect(Rect2(-116, 34, 232, 18), Color("#333f3f"))
	draw_line(Vector2(-104, 36), Vector2(104, 36), Color("#818b7f"), 2)
