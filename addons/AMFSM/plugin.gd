@tool
extends EditorPlugin

var plugin


func _enter_tree() -> void:
	plugin = preload("res://addons/AMFSM/amfsm_inspector.gd").new()
	plugin.set_host_plugin(self)
	add_inspector_plugin(plugin)
	plugin.set_visual_editor_button(add_control_to_bottom_panel(plugin.get_visual_editor(), "AMFSM Editor"))


func _exit_tree() -> void:
	remove_inspector_plugin(plugin)
