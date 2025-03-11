@tool
extends Control
class_name AmfsmVisualState


signal state_location_changed(state: AmfsmVisualState)


@export var zoom := 1.0
@export var state_name := &""
@export var state_location := Vector2.ZERO:
	set(val):
		state_location = val
		state_location_changed.emit()

var dragging := false


func _ready() -> void:
	state_location -= size * 0.5


func set_state_name(_name: StringName) -> void:
	$Name.text = _name
	state_name = _name


func _gui_input(event: InputEvent) -> void:
	if dragging and event is InputEventMouseMotion:
		state_location += event.relative / zoom
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
