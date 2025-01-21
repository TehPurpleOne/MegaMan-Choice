@tool
extends Node2D

func _draw() -> void:
	if !Engine.is_editor_hint(): return # If the game editor is not detected, do not draw the rect.
	
	# Draws a red rectangle around the border of a section.
	var parent = get_parent()
	var parent_size: Vector2 = parent.get("size")
	var rect_size = Rect2(Vector2.ZERO, parent_size)
	draw_rect(rect_size, Color(1, 0, 0), false, 4)
