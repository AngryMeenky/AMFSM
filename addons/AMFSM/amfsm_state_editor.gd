@tool
extends VBoxContainer
class_name AmfsmStateEditor


signal request_remove_state(state: AmfsmStateEditor)

signal request_remove_transition(state: AmfsmStateEditor, trigger: StringName)
signal request_add_transition(state: AmfsmStateEditor, trigger: StringName, target: StringName)

signal request_select_callback(state: AmfsmStateEditor, event: StringName)
signal request_add_callback(state: AmfsmStateEditor, event: StringName, path: NodePath)
signal request_remove_callback(state: AmfsmStateEditor, event: StringName, path: NodePath)


@onready var transition_list := $State/VBox/Transitions/VBox/Transitions
@onready var transition_add := $State/VBox/Transitions/VBox/AddTransition
@onready var add_new_transition := $State/VBox/Transitions/VBox/AddTransition/VBox/Create/AddNew
@onready var trigger := $State/VBox/Transitions/VBox/AddTransition/VBox/Create/Trigger
@onready var targets := $State/VBox/Transitions/VBox/AddTransition/VBox/Create/Target
@onready var callbacks := $State/VBox/Callbacks/VBox/Callbacks
@onready var transitions := $State/VBox/Callbacks/VBox/AddCallback/VBox/Create/TransitionList
@onready var callable_select := $State/VBox/Callbacks/VBox/AddCallback/VBox/Create/CallableButton
@onready var add_new_callback := $State/VBox/Callbacks/VBox/AddCallback/VBox/Create/AddNew

var by_name := {}
var by_action := { "enter": {}, "stay": {}, "exit": {} }
var raw_state := {}
var state_name := &""
var callable_path := ^""
var callback_root: TreeItem = null
var in_order: Array[StringName] = []
var alphabetical: Array[StringName] = []


func _ready() -> void:
	callback_root = callbacks.create_item()
	for idx in transitions.item_count:
		var text: String = transitions.get_item_text(idx)
		var item := callback_root.create_child()
		item.set_text(0, text)
		item.set_icon(0, preload("res://addons/AMFSM/icons/Signal.svg"))
		transitions.set_item_metadata(idx, [ StringName(text), item ])
		by_action[text]["[tree-root]"] = item


func _disable_action(idx: int, disabled: bool) -> void:
	transitions.set_item_disabled(idx, disabled)
	by_action[transitions.get_item_text(idx)]["[tree-root]"].visible = not disabled


func set_state_name(_name: StringName) -> void:
	state_name = _name
	var header := $StateHeader
	var t_header := $State/VBox/TransitionsHeader
	header.section_name = _name
	match _name:
		AMFiniteStateMachine.START:
			t_header.visible = true
			transition_add.visible = true
			transition_list.visible = true
			header.allow_removal = false
			_disable_action(2, false)
		AMFiniteStateMachine.ERROR, AMFiniteStateMachine.FINAL:
			t_header.visible = false
			transition_add.visible = false
			transition_list.visible = false
			header.allow_removal = false
			_disable_action(2, _name == AMFiniteStateMachine.ERROR)
		_:
			t_header.visible = true
			transition_add.visible = true
			transition_list.visible = true
			header.allow_removal = true
			_disable_action(2, false)


func set_raw_state(raw: Dictionary) -> void:
	raw_state = raw

	var transitions: Dictionary = raw.get("transitions", {})
	# ensure all the specified transitions are displayed
	for trigger in transitions.keys():
		add_transition(trigger, transitions[trigger])
	# ensure that no unspecified transitions are displayed
	for trigger in by_name.keys():
		if trigger not in transitions:
			remove_transition(trigger)

	_update_callbacks(raw, &"enter")
	_update_callbacks(raw, &"stay")
	_update_callbacks(raw, &"exit")



func get_raw_state() -> Dictionary:
	return raw_state


func _update_callbacks(raw: Dictionary, action: StringName) -> void:
	var callbacks: Array = raw.get(action, [])
	var changed := false
	for callback in callbacks:
		changed = changed or add_callback(action, callback)
	for callback in by_action[action].keys():
		if str(callback) not in callbacks:
			changed = changed or remove_callback(action, callback)
	if changed:
		self.callbacks.update_minimum_size()


func callback_selected(path: NodePath) -> void:
	if path.is_empty():
		add_new_callback.disabled = true
		callable_select.text = "Callable"
	else:
		add_new_callback.disabled = false
		callable_select.text = "%s::%s" % [ path.get_concatenated_names(), path.get_concatenated_subnames() ]
	callable_path = path


func get_state_name() -> StringName:
	return state_name


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
		transition_list.add_child(display[0])
		transition_list.add_child(display[1])
		transition_list.add_child(display[2])
		by_name[trigger] = display
		var idx := in_order.bsearch(trigger)
		in_order.insert(idx, trigger)
		transition_list.move_child(display[0], idx * 3 + 3)
		transition_list.move_child(display[1], idx * 3 + 4)
		transition_list.move_child(display[2], idx * 3 + 5)
	else:
		var idx := in_order.bsearch(trigger)
		(transition_list.get_child(idx * 3 + 4) as Label).text = target


func remove_transition(trigger: StringName) -> void:
	var display: Array = by_name.get(trigger, [])
	if not display.is_empty():
		transition_list.remove_child(display[0])
		transition_list.remove_child(display[1])
		transition_list.remove_child(display[2])
		in_order.erase(trigger)
	by_name.erase(trigger)


func add_callback(event: StringName, callable: NodePath) -> bool:
	var dict: Dictionary = by_action[event]
	var root: TreeItem = dict["[tree-root]"]
	var display: TreeItem = dict.get(callable)
	if display == null:
		display = root.create_child()
		display.set_icon(0, preload("res://addons/AMFSM/icons/Slot.svg"))
		display.set_text(0, "%s::%s" % [ callable.get_concatenated_names(), callable.get_concatenated_subnames()])
		display.add_button(1, preload("res://addons/AMFSM/icons/Remove.svg"), -1, false, "Remove")
		display.set_metadata(0, [ event, callable ])
		dict[callable] = display
		return true
	return false


func remove_callback(event: StringName, callable: NodePath) -> bool:
	var dict: Dictionary = by_action[event]
	var root: TreeItem = dict["[tree-root]"]
	var display: TreeItem = dict.get(callable)
	if display != null:
		dict.erase(callable)
		root.remove_child(display)
		display.free()
		return true
	return false


func _on_add_new_pressed() -> void:
	request_add_transition.emit(self,StringName(trigger.text), targets.get_item_metadata(targets.selected))
	trigger.text = ""
	targets.select(-1)


func _on_target_selected(index: int) -> void:
	add_new_transition.disabled = index < 0 or trigger.text.is_empty()


func _on_trigger_changed(new_text: String) -> void:
	add_new_transition.disabled = new_text.is_empty() or targets.selected < 0


func _on_trigger_submitted(new_text: String) -> void:
	if not add_new_transition.disabled:
		_on_add_new_pressed() # simulate a button press on enter


func _on_toggle_pressed() -> void:
	var box := $VBox
	box.visible = not box.visible


func _on_remove_transition_pressed(trigger: StringName) -> void:
	request_remove_transition.emit(self, trigger)


func _on_remove_state_pressed() -> void:
	request_remove_state.emit(self)


func _on_state_toggled(expanded: bool) -> void:
	$State.visible = expanded


func _on_transitions_toggled(expanded: bool) -> void:
	$State/VBox/Transitions.visible = expanded


func _on_callbacks_toggled(expanded: bool) -> void:
	$State/VBox/Callbacks.visible = expanded


func _on_add_new_callback_pressed() -> void:
	request_add_callback.emit(self, transitions.get_item_metadata(transitions.selected)[0], callable_path)
	callable_select.text = "Callable"
	callable_path = ^""


func _on_callable_select_pressed() -> void:
	request_select_callback.emit(self, transitions.get_item_metadata(transitions.selected)[0])



func _on_callbacks_button_clicked(item: TreeItem, _column: int, _id: int, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_LEFT:
		var args: Array = item.get_metadata(0)
		request_remove_callback.emit(self, args[0], args[1])
