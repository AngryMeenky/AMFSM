@tool
extends MarginContainer
class_name AmfsmVisualEditor

const _ZOOM: PackedFloat32Array = [
	0.0625, 0.125, 0.25, 1.0/3.0, 0.5, 2.0/3.0, 0.75, 0.875, 1.0, # up to 100%
	1.5,    2.0,   2.5,  3.0,     4.0, 5.0,     6.0,  7.0,   8.0 # up to 800%
]

var by_name := {}
var verts := {}
var changed := true
var _host: EditorPlugin = null
var zoom_idx: int = _ZOOM.bsearch(1.0)
var states: Array[AmfsmVisualState] = []

@onready var _grid: Panel = $Grid
@onready var _states: Control = $States
@onready var _zoom_in: Button = $Controls/In
@onready var _zoom_out: Button = $Controls/Out
@onready var _zoom_amount: Label = $Controls/Amount


func _ready() -> void:
	_grid.zoom = _ZOOM[zoom_idx]


func _process(delta: float) -> void:
	if not (visible and changed):
		return

	changed = false
	for state in states:
		state.process_repulsion(states)
	for state in states:
		if state.forces.is_zero_approx():
			continue
		changed = true
		state.state_location += state.forces * delta


func set_plugin_host(host: EditorPlugin) -> void:
	_host = host


func set_states(_by_name: Dictionary) -> void:
	by_name = _by_name
	print(by_name)


func update_states(new_order: Array[StringName]) -> void:
	for idx in new_order.size():
		var state: AmfsmVisualState = verts.get(new_order[idx])
		if state == null:
			state = preload("res://addons/AMFSM/amfsm_visual_state.tscn").instantiate()
			verts[new_order[idx]] = state
			_states.add_child(state)
			state.set_state_name(new_order[idx])
			state.state_location_changed.connect(_place_state.bind(state))
			state.state_location = Vector2.RIGHT.rotated(idx * PI * 2.0 / new_order.size()) * 128.0
			_place_state.call_deferred(state)
			states.append(state)
			changed = true
		_states.move_child(state, idx)
		#TODO: update transitions

	# remove deleted state
	for state_name in verts.keys():
		if not by_name.has(state_name):
			var state: AmfsmVisualState = verts[state_name]
			verts.erase(state_name)
			_states.remove_child(state)
			state.queue_free()
			changed = true


func _place_states() -> void:
	var zoom: float = _grid.zoom
	var center: Vector2  = _grid.size * 0.5 + _grid.grid_offset * zoom
	for state in states:
		state.zoom = zoom
		state.position = state.state_location * zoom + center


func _place_state(state: AmfsmVisualState) -> void:
	var zoom: float = _grid.zoom
	state.zoom = zoom
	state.position = state.state_location * zoom + _grid.size * 0.5 + _grid.grid_offset * zoom
	changed = true



func _on_center_view() -> void:
	_grid.grid_offset = Vector2.ZERO
	_place_states()


func _on_zoom_in() -> void:
	var last := _ZOOM.size() - 1
	var next := zoom_idx + 1
	if next <= last:
		_zoom_out.disabled = false
		_zoom_in.disabled = next == last
		zoom_idx = next
		_grid.zoom = _ZOOM[zoom_idx]
		_zoom_amount.text = "%5.1f%%" % (_ZOOM[zoom_idx] * 100)
		_place_states()


func _on_reset_zoom() -> void:
	_zoom_in.disabled = false
	_zoom_out.disabled = false
	zoom_idx = _ZOOM.bsearch(1.0)
	_grid.zoom = 1.0
	_zoom_amount.text = "%5.1f%%" % (_ZOOM[zoom_idx] * 100)
	_place_states()


func _on_zoom_out() -> void:
	var next := zoom_idx - 1
	if next >= 0:
		_zoom_in.disabled = false
		_zoom_out.disabled = next == 0
		zoom_idx = next
		_grid.zoom = _ZOOM[zoom_idx]
		_zoom_amount.text = "%5.1f%%" % (_ZOOM[zoom_idx] * 100)
		_place_states()
