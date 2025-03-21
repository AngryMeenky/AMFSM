@tool
extends EditorProperty
class_name AmfsmMachineEditor

static var STATE_EDITOR := preload("res://addons/AMFSM/amfsm_state_editor.tscn")

@onready var bottom_editor := $BottomEditor
@onready var states := $BottomEditor/VBox/States
@onready var add_new_state := $BottomEditor/VBox/HBox/NewState
@onready var new_state_name := $BottomEditor/VBox/HBox/NewName
@onready var callback_dialog := $CallableSelectionDialog

var by_name := {}
var in_order: Array[StringName] = []
var alphabetical: Array[StringName] = []
var edited_state: AmfsmStateEditor = null
var visual_editor: AmfsmVisualEditor = null



func _ready() -> void:
	add_focusable($Activator)
	add_focusable(add_new_state)
	add_focusable(new_state_name)
	set_bottom_editor(bottom_editor)


func set_visual_editor(visual: AmfsmVisualEditor) -> void:
	visual_editor = visual
	if visual != null:
		visual.set_states(by_name)


func _get_edited_value() -> Array[Dictionary]:
	return get_edited_object()[get_edited_property()]


func _update_property():
	var raw_states: Array[Dictionary] = _get_edited_value()
	var new_order: Array[StringName] = []

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
		alphabetical.sort_custom(
			func(lhs: StringName, rhs: StringName) -> bool:
				return lhs.naturalcasecmp_to(rhs) == -1
		)

		# reorder the children and update the target list for each state
		for idx in new_order.size():
			var state: AmfsmStateEditor = by_name[new_order[idx]]
			state.set_available_states(alphabetical)
			states.move_child(state, idx)

		# remove the superfluous children
		for idx in range(states.get_child_count(), new_order.size(), -1):
			var state: AmfsmStateEditor = states.get_child(idx - 1)
			by_name.erase(state.get_state_name())
			state.request_remove_state.disconnect(_on_request_remove_state)
			state.request_add_transition.disconnect(_on_request_add_transition)
			state.request_remove_transition.disconnect(_on_request_remove_transition)
			state.request_add_callback.disconnect(_on_request_add_callback)
			state.request_remove_callback.disconnect(_on_request_remove_callback)
			state.request_select_callback.disconnect(_on_request_select_callback)
			states.remove_child(state)
			state.queue_free()

		visual_editor.update_states(new_order) # alert the visual editor
		in_order = new_order # record the change


func _build_state(raw: Dictionary) -> AmfsmStateEditor:
	var state := STATE_EDITOR.instantiate()
	states.add_child(state) # needs to be in the tree for node resolution to have occured
	add_focusable(state.trigger)
	add_focusable(state.targets)
	add_focusable(state.add_new_transition)
	add_focusable(state.transitions)
	state.set_state_name(raw["name"])
	_update_state(state, raw)
	state.request_remove_state.connect(_on_request_remove_state)
	state.request_add_transition.connect(_on_request_add_transition)
	state.request_remove_transition.connect(_on_request_remove_transition)
	state.request_add_callback.connect(_on_request_add_callback)
	state.request_remove_callback.connect(_on_request_remove_callback)
	state.request_select_callback.connect(_on_request_select_callback)

	return state


func _update_state(state: AmfsmStateEditor, raw: Dictionary) -> void:
	state.set_available_states(alphabetical)
	state.set_raw_state(raw)


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


func _on_request_add_callback(state: AmfsmStateEditor, action: StringName, path: NodePath):
	var state_name := state.get_state_name()
	var raw: Array[Dictionary] = _get_edited_value()
	for idx in raw.size():
		if raw[idx]["name"] == state_name:
			var raw_state := raw[idx].duplicate(true)
			var callbacks: Array = raw_state.get_or_add(action, [])
			if path not in callbacks:
				raw = raw.duplicate()
				raw[idx] = raw_state
				callbacks.append(str(path))
				emit_changed(get_edited_property(), raw)


func _on_request_remove_callback(state: AmfsmStateEditor, action: StringName, path: NodePath):
	var state_name := state.get_state_name()
	var raw: Array[Dictionary] = _get_edited_value()
	for idx in raw.size():
		if raw[idx]["name"] == state_name:
			var raw_state := raw[idx].duplicate(true)
			var callbacks: Array = raw_state.get(action, [])
			var index := callbacks.find(str(path))
			if index >= 0:
				raw = raw.duplicate()
				raw[idx] = raw_state
				callbacks.remove_at(index)
				emit_changed(get_edited_property(), raw)


func _on_request_select_callback(state: AmfsmStateEditor, action: StringName):
	edited_state = state
	callback_dialog.activate(get_edited_object(), action, state.get_state_name(), EditorInterface.get_edited_scene_root())


func _on_callable_selected(node: Node, method: String) -> void:
	var fsm := get_edited_object() as AMFiniteStateMachine
	var resolve := fsm.get_node_or_null(fsm.resolve_root)
	if resolve != null:
		var script = node.get_script()
		if script != null:
			var path := NodePath("%s:%s" % [resolve.get_path_to(node), method])
			EditorInterface.edit_script(script)
			var editor := EditorInterface.get_script_editor().get_current_editor()
			if not _has_method(script, method):
				var code: CodeEdit = editor.get_base_editor()
				var line := code.get_line_count()
				code.deselect()
				code.insert_text(
					"\n\nfunc %s(fsm: AMFiniteStateMachine, state: StringName) -> void:\n\tpass\n" % method,
					 line - 1,
					 0
				)
				code.set_caret_line(line + 2)
				#EditorInterface.save_scene()
				#script.reload(true)
			else:
				editor.go_to_method.emit(script, method)
			edited_state.callback_selected(path)
		else:
			printerr("Selected node does not have an attached script: %s" % node.get_path())
	else:
		printerr("Unable to find the resolve root: %s" % fsm.resolve_root)


func _has_method(script: Script, method: String) -> bool:
	for proto in script.get_script_method_list():
		if proto["name"] == method:
			return true
	return false
