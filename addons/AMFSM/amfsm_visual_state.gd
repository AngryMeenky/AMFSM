@tool
extends PanelContainer
class_name AmfsmVisualState


signal state_location_changed(state: AmfsmVisualState)


@export var zoom := 1.0
@export var state_name := &""
@export var state_location := Vector2.ZERO:
	set(val):
		state_location = val
		state_location_changed.emit()

@onready var name_plate := $VBox/NamePlate
@onready var outbound := $Outbound

var dragging := false
var draggable := true
var forces := Vector2.ZERO


func _ready() -> void:
	var offset = size * 0.5
	state_location -= offset
	name_plate.resized.connect(_on_resized)
	_on_resized()


func set_state_name(_name: StringName) -> void:
	$VBox/NamePlate/Name.text = _name
	$VBox/NamePlate/Name.update_minimum_size()
	size = get_minimum_size()
	state_name = _name
	match _name:
		AMFiniteStateMachine.START, AMFiniteStateMachine.FINAL, AMFiniteStateMachine.ERROR:
			$VBox/NamePlate/Remove.disabled = true
		_:
			$VBox/NamePlate/Remove.disabled = false


func process_repulsion(states: Array[AmfsmVisualState]) -> void:
	var shoves := Vector2.ZERO
	if draggable:
		var here: Vector2 = outbound.global_position

		for state in states:
			if state == self:
				continue
			var shove: Vector2 = here - state.outbound.global_position
			if shove.length_squared() < 16384.0:
				shoves += shove.normalized() * (128 - shove.length())

	forces = shoves


func _gui_input(event: InputEvent) -> void:
	if dragging and event is InputEventMouseMotion:
		state_location += event.relative / zoom
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed and draggable


func _on_resized() -> void:
	outbound.position = name_plate.position + name_plate.size * 0.5


func _on_pinned(on: bool) -> void:
	draggable = not on
