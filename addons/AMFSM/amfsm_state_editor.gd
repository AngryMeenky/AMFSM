@tool
extends VBoxContainer
class_name AmfsmStateEditor


signal request_remove_state(state: AmfsmStateEditor)
signal request_remove_transition(state: AmfsmStateEditor, trigger: StringName)
signal request_add_transition(state: AmfsmStateEditor, trigger: StringName, target: StringName)


@onready var index := $HBox/Index
@onready var remove := $HBox/Remove
@onready var activator := $HBox/Toggle
@onready var list := $VBox/Transitions
@onready var add := $VBox/AddTransition
@onready var add_new := $VBox/AddTransition/VBox/AddNew
@onready var trigger := $VBox/AddTransition/VBox/Create/Trigger
@onready var targets := $VBox/AddTransition/VBox/Create/Target

var by_name := {}
var state_name := &""
var in_order: Array[StringName] = []
var alphabetical: Array[StringName] = []


func set_state_name(_name: StringName) -> void:
	state_name = _name
	activator.text = _name
	match _name:
		FiniteStateMachine.START:
			add.visible = true
			list.visible = true
			remove.disabled = true
		FiniteStateMachine.ERROR, FiniteStateMachine.FINAL:
			add.visible = false
			list.visible = false
			remove.disabled = true
		_:
			add.visible = true
			list.visible = true


func get_state_name() -> StringName:
	return state_name


func set_index(idx: int) -> void:
	index.text = str(idx)


func set_available_states(states: Array[StringName]) -> void:
	if alphabetical.hash() != states.hash():
		targets.clear()
		for idx in states.size():
			var state := states[idx]
			targets.add_item(state)
			targets.set_item_metadata(idx, state)


func get_current_triggers() -> Array[StringName]:
	return in_order


func add_transition(trigger: StringName, target: StringName) -> void:
	if trigger not in by_name:
		var display: Array = [ Label.new(), Label.new(), Button.new() ]
		display[0].text = trigger
		display[1].text = target
		display[2].icon = preload("res://addons/AMFSM/icons/Remove.svg")
		display[2].pressed.connect(_on_remove_transition_pressed.bind(trigger))
		list.add_child(display[0])
		list.add_child(display[1])
		list.add_child(display[2])
		by_name[trigger] = display
		var idx := in_order.bsearch(trigger)
		in_order.insert(idx, trigger)
		list.move_child(display[0], idx * 3 + 3)
		list.move_child(display[1], idx * 3 + 4)
		list.move_child(display[2], idx * 3 + 5)
		print(list.get_children())
	else:
		var idx := in_order.bsearch(trigger)
		(list.get_child(idx * 3 + 4) as Label).text = target


func remove_transition(trigger: StringName) -> void:
	var display: Array = by_name.get(trigger, [])
	if not display.is_empty():
		list.remove_child(display[0])
		list.remove_child(display[1])
		list.remove_child(display[2])
		in_order.erase(trigger)
	by_name.erase(trigger)


func _on_add_new_pressed() -> void:
	request_add_transition.emit(self,StringName(trigger.text), targets.get_item_metadata(targets.selected))
	trigger.text = ""
	targets.select(-1)


func _on_target_selected(index: int) -> void:
	add_new.disabled = index < 0 or trigger.text.is_empty()


func _on_trigger_changed(new_text: String) -> void:
	add_new.disabled = new_text.is_empty() or targets.selected < 0


func _on_trigger_submitted(new_text: String) -> void:
	if not add_new.disabled:
		_on_add_new_pressed() # simulate a button press on enter


func _on_toggle_pressed() -> void:
	var box := $VBox
	box.visible = not box.visible


func _on_remove_transition_pressed(trigger: StringName) -> void:
	request_remove_transition.emit(self, trigger)


func _on_remove_state_pressed() -> void:
	request_remove_state.emit(self)
