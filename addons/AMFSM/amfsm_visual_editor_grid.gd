@tool
extends Panel


signal grid_offset_changed()


@export_range(0.0625, 8, 0.0625) var zoom := 1.0:
	set(val):
		zoom = val
		queue_redraw()

@export_group("Grid Settings", "grid_")
@export var grid_draw_lines := true:
	set(val):
		grid_draw_lines = val
		queue_redraw()
@export var grid_color := Color.SKY_BLUE:
	set(val):
		grid_color = val
		queue_redraw()
@export var grid_draw_background := true:
	set(val):
		grid_draw_background = val
		queue_redraw()
@export var grid_background := Color.DARK_SLATE_GRAY:
	set(val):
		grid_background = val
		queue_redraw()
@export_range(4, 512, 1) var grid_spacing := 64:
	set(val):
		grid_spacing = val
		queue_redraw()
@export_range(1, 16, 1) var grid_width := 1:
	set(val):
		grid_width = val
		queue_redraw()
@export var grid_offset := Vector2.ZERO:
	set(val):
		grid_offset = val
		queue_redraw()
		grid_offset_changed.emit()

var dragging := false
var grid_lines := PackedVector2Array()


func _draw() -> void:
	if grid_draw_background:
		draw_rect(Rect2(Vector2.ZERO, self.size), grid_background)

	if grid_draw_lines:
		var spacing = grid_spacing * zoom
		var cam = size * -0.5 - grid_offset * zoom
		cam.x = fmod(cam.x, spacing)
		cam.y = fmod(cam.y, spacing)

		var count := Vector2i(int(size.x / spacing) + 1, int(size.y / spacing) + 1)
		grid_lines.clear()
		grid_lines.resize((count.x + count.y) * 2)

		for i in range(count.x):
			grid_lines.append(Vector2(i * spacing - cam.x, 0.0   ))
			grid_lines.append(Vector2(i * spacing - cam.x, size.y))
		for i in range(count.y):
			grid_lines.append(Vector2(0.0,    i * spacing - cam.y))
			grid_lines.append(Vector2(size.x, i * spacing - cam.y))

		draw_multiline(grid_lines, grid_color, grid_width)


func _unhandled_input(event):
	if dragging and event is InputEventMouseMotion:
		grid_offset += event.relative / zoom
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
