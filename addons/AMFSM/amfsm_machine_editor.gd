@tool
extends EditorProperty
class_name AmfsmMachineEditor

static var STATE_EDITOR := preload("res://addons/AMFSM/amfsm_state_editor.tscn")

@onready var bottom_editor := $BottomEditor
@onready var states := $BottomEditor/VBox/States
@onready var add_new_state := $BottomEditor/VBox/HBox/NewState
@onready var new_state_name := $BottomEditor/VBox/HBox/NewName
@onready var size_display := $BottomEditor/VBox/Stats/SizeDisplay

var by_name := {}
var in_order: Array[StringName] = []
var alphabetical: Array[StringName] = []


func _ready() -> void:
	add_focusable($Activator)
	add_focusable(add_new_state)
	add_focusable(new_state_name)
	set_bottom_editor(bottom_editor)


func _get_edited_value() -> Array[Dictionary]:
	return get_edited_object()[get_edited_property()]


func _update_property():
	var raw_states: Array[Dictionary] = _get_edited_value()
	var new_order: Array[StringName] = []
	size_display.text = str(raw_states.size())

	# run through each state to apply possible updates
	for state in raw_states:
		var _name: StringName = state["name"]
		new_order.append(_name)
		if _name not in by_name:
			var new_state := _build_state(state)
			by_name[_name] = new_state
		else:
			_update_state(by_name[_name], state)

	# is the ordering different?
	if in_order.hash() != new_order.hash():
		alphabetical = new_order.duplicate()
		alphabetical.sort()

		# reorder the children and update the target list for each state
		for idx in new_order.size():
			var state: AmfsmStateEditor = by_name[new_order[idx]]
			state.set_available_states(alphabetical)
			state.set_index(idx)
			states.move_child(state, idx)

		# remove the superfluous children
		for idx in range(states.get_child_count(), new_order.size(), -1):
			var state: AmfsmStateEditor = states.get_child(idx - 1)
			by_name.erase(state.get_state_name())
			state.request_remove_state.disconnect(_on_request_remove_state)
			state.request_add_transition.disconnect(_on_request_add_transition)
			state.request_remove_transition.disconnect(_on_request_remove_transition)
			states.remove_child(state)
			state.queue_free()
		in_order = new_order # record the change


func _build_state(raw: Dictionary) -> AmfsmStateEditor:
	var state := STATE_EDITOR.instantiate()
	states.add_child(state) # needs to be in the tree for node resolution to have occured
	add_focusable(state.activator)
	add_focusable(state.trigger)
	add_focusable(state.targets)
	add_focusable(state.add_new)
	state.set_state_name(raw["name"])
	_update_state(state, raw)
	state.request_remove_state.connect(_on_request_remove_state)
	state.request_add_transition.connect(_on_request_add_transition)
	state.request_remove_transition.connect(_on_request_remove_transition)

	return state


func _update_state(state: AmfsmStateEditor, raw: Dictionary) -> void:
	state.set_available_states(alphabetical)
	var transitions: Dictionary = raw.get("transitions", {})
	# ensure all the specified transitions are displayed
	for trigger in transitions.keys():
		state.add_transition(trigger, transitions[trigger])
	# ensure that no unspecified transitions are displayed
	for trigger in state.by_name.keys():
		if trigger not in transitions:
			state.remove_transition(trigger)


func _on_activator_pressed() -> void:
	bottom_editor.visible = not bottom_editor.visible


func _on_new_state_pressed() -> void:
	var new_name = StringName(new_state_name.text)
	if new_name not in by_name:
		var raw: Array[Dictionary] = _get_edited_value()
		raw = raw.duplicate()
		raw.append({ "name": new_name })
		emit_changed(get_edited_property(), raw)
		new_state_name.text = ""
		add_new_state.disabled = true


func _on_new_name_changed(new_text: String) -> void:
	add_new_state.disabled = new_text.is_empty()


func _on_request_remove_state(state: AmfsmStateEditor):
	var removed: int = -1
	var state_name := state.get_state_name()
	var raw: Array[Dictionary] = _get_edited_value()
	for idx in raw.size():
		if raw[idx]["name"] == state_name:
			removed = idx # don't modify the array during iteration
		else:
			# remove any transitions where this state was the target
			var transitions: Dictionary = raw[idx].get("transitions", {})
			for trigger in transitions.keys():
				if transitions[trigger] == state_name:
					transitions.erase(trigger)

	# perform the actual removal
	if removed >= 0:
		raw = raw.duplicate()
		raw.remove_at(removed)
		emit_changed(get_edited_property(), raw)


func _on_request_remove_transition(state: AmfsmStateEditor, trigger: StringName):
	var state_name := state.get_state_name()
	var raw: Array[Dictionary] = _get_edited_value()
	for idx in raw.size():
		if raw[idx]["name"] == state_name:
			var transitions: Dictionary = raw[idx].get("transitions", {})
			if trigger in transitions:
				raw = raw.duplicate()
				raw[idx] = raw[idx].duplicate(true)
				raw[idx]["transitions"].erase(trigger)
				emit_changed(get_edited_property(), raw)
			break


func _on_request_add_transition(state: AmfsmStateEditor, trigger: StringName, target: StringName):
	var state_name := state.get_state_name()
	var raw: Array[Dictionary] = _get_edited_value()
	for idx in raw.size():
		if raw[idx]["name"] == state_name:
			raw = raw.duplicate()
			raw[idx] = raw[idx].duplicate(true)
			var transitions: Dictionary = raw[idx].get_or_add("transitions", {})
			if trigger not in transitions or transitions[trigger] != target:
				transitions[trigger] = target
				emit_changed(get_edited_property(), raw)
			break
