extends EditorInspectorPlugin


var amfsm_machine_editor = preload("res://addons/AMFSM/amfsm_machine_editor.tscn")


func _can_handle(object) -> bool:
	return object is FiniteStateMachine # only process finite state machines


func _parse_property(fsm: Object, type: Variant.Type, prop: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	if type == TYPE_ARRAY and prop == "states":
		add_property_editor(prop, amfsm_machine_editor.instantiate())
		return true
	return false
