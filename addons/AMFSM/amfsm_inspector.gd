extends EditorInspectorPlugin


var amfsm_machine_editor = preload("res://addons/AMFSM/amfsm_machine_editor.tscn")
var amfsm_visual_editor: AmfsmVisualEditor = null
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
		var editor = amfsm_machine_editor.instantiate()
		editor.set_visual_editor(amfsm_visual_editor)
		add_property_editor(prop, editor)
		return true
	return false


func set_host_plugin(_host: EditorPlugin) -> void:
	host = _host


func get_visual_editor() -> Control:
	if amfsm_visual_editor == null:
		amfsm_visual_editor = preload("res://addons/AMFSM/amfsm_visual_editor.tscn").instantiate()
		amfsm_visual_editor.set_plugin_host(host)
	return amfsm_visual_editor


func set_visual_editor_button(button: Button) -> void:
	amfsm_visual_editor_button = button
	if button != null:
		button.visible = false
	else:
		amfsm_visual_editor.queue_free()
		amfsm_visual_editor = null
