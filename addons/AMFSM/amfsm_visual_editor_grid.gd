@tool
extends Node2D


@onready var camera := $"../Camera2D"
@export_group("Grid Settings", "grid_")
@export var grid_draw_lines := true
@export var grid_color := Color.SKY_BLUE
@export var grid_draw_background := true
@export var grid_background := Color.DARK_SLATE_GRAY
@export var grid_spacing := 64
@export var grid_width := 1

var grid_lines := PackedVector2Array()


# Called when the node enters the scene tree for the first time.
func _draw() -> void:
	var view := get_viewport_rect()
	var size = view.size * camera.zoom / 2

	if grid_draw_background:
		view.position -= size
		draw_rect(view, grid_background)

	if grid_draw_lines:
		var cam = camera.position
		var start := Vector2i(int((cam.x - size.x) / grid_spacing) - 1, int((cam.y - size.y) / grid_spacing) - 1)
		var end := Vector2i(int((size.x + cam.x) / grid_spacing) + 1, int((size.y + cam.y) / grid_spacing) + 1)
		grid_lines.clear()
		grid_lines.resize(((end.x - start.x) + (end.y - start.y)) * 2)

		for i in range(start.x, end.x):
			grid_lines.append(Vector2(i * grid_spacing, cam.y + size.y))
			grid_lines.append(Vector2(i * grid_spacing, cam.y - size.y))
		for i in range(start.y, end.y):
			grid_lines.append(Vector2(cam.x + size.x, i * grid_spacing))
			grid_lines.append(Vector2(cam.x - size.x, i * grid_spacing))

		draw_multiline(grid_lines, grid_color, grid_width)
