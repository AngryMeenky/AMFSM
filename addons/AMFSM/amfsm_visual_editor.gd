@tool
extends MarginContainer
class_name AmfsmVisualEditor

const _ZOOM: PackedFloat32Array = [
	0.0625, 0.125, 0.25, 1.0/3.0, 0.5, 2.0/3.0, 0.75, 0.875, 1.0, # up to 100%
	1.5,    2.0,   2.5,  3.0,     4.0, 5.0,     6.0,  7.0,   8.0 # up to 800%
]

var by_name := {}
var verts := {}
var _host: EditorPlugin = null
var zoom_idx: int = _ZOOM.bsearch(1.0)

@onready var _grid: Panel = $Grid
@onready var _ui: MarginContainer = $UI
@onready var _zoom_in: Button = $UI/VBox/Controls/In
@onready var _zoom_out: Button = $UI/VBox/Controls/Out
@onready var _zoom_amount: Label = $UI/VBox/Controls/Amount


func _ready() -> void:
	_grid.zoom = _ZOOM[zoom_idx]


func set_plugin_host(host: EditorPlugin) -> void:
	_host = host


func set_states(_by_name: Dictionary) -> void:
	by_name = _by_name


func update_states(new_order: Array[StringName]) -> void:
	prints(new_order)


func _on_center_view() -> void:
	_grid.grid_offset = Vector2.ZERO


func _on_zoom_in() -> void:
	var last := _ZOOM.size() - 1
	var next := zoom_idx + 1
	if next <= last:
		_zoom_out.disabled = false
		_zoom_in.disabled = next == last
		zoom_idx = next
		_grid.zoom = _ZOOM[zoom_idx]
		_zoom_amount.text = "%5.1f%%" % (_ZOOM[zoom_idx] * 100)


func _on_reset_zoom() -> void:
	_zoom_in.disabled = false
	_zoom_out.disabled = false
	zoom_idx = _ZOOM.bsearch(1.0)
	_grid.zoom = 1.0
	_zoom_amount.text = "%5.1f%%" % (_ZOOM[zoom_idx] * 100)


func _on_zoom_out() -> void:
	var next := zoom_idx - 1
	if next >= 0:
		_zoom_in.disabled = false
		_zoom_out.disabled = next == 0
		zoom_idx = next
		_grid.zoom = _ZOOM[zoom_idx]
		_zoom_amount.text = "%5.1f%%" % (_ZOOM[zoom_idx] * 100)
