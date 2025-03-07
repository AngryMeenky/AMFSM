extends EditorInspectorPlugin


var amfsm_machine_editor = preload("res://addons/AMFSM/amfsm_machine_editor.tscn")
var amfsm_visual_editor = preload("res://addons/AMFSM/amfsm_visual_editor.tscn").instantiate()
var amfsm_visual_editor_button: Button = null
var host: EditorPlugin = null


func _can_handle(object) -> bool:
	var handle := object is AMFiniteStateMachine # only process finite state machines
	amfsm_visual_editor_button.visible = handle
	if not handle and amfsm_visual_editor.visible:
		host.hide_bottom_panel()
	elif handle and not amfsm_visual_editor.visible:
		host.make_bottom_panel_item_visible(amfsm_visual_editor)
	return handle


func _parse_property(fsm: Object, type: Variant.Type, prop: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	if type == TYPE_ARRAY and prop == "states":
		add_property_editor(prop, amfsm_machine_editor.instantiate())
		return true
	return false


func set_host_plugin(_host: EditorPlugin) -> void:
	host = _host


func get_visual_editor() -> Control:
	return amfsm_visual_editor


func set_visual_editor_button(button: Button) -> void:
	amfsm_visual_editor_button = button
	button.visible = false
