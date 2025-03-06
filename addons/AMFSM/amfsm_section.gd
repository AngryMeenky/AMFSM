@tool
extends PanelContainer
class_name AmfsmSectionHeader


signal remove_pressed()
signal toggled(expanded: bool)


@onready var _toggle := $Header/CheckButton as CheckButton
@onready var _name := $Header/Label as Label


@export var section_name := "Section":
	set(val):
		section_name = val
		($Header/Label if _name == null else _name).text = val
@export var expanded := false:
	set(val):
		($Header/CheckButton if _toggle == null else _toggle).set_pressed(val)
	get:
		return ($Header/CheckButton if _toggle == null else _toggle).button_pressed
@export var allow_removal := false:
	set(val):
		allow_removal = val
		$Header/Button.visible = val


func set_section_name(nam: String) -> void:
	($Header/Label if _name == null else _name).text = nam


func _on_mouse_entered() -> void:
	theme_type_variation = &"PanelContainerHighlight"


func _on_mouse_exited() -> void:
	theme_type_variation = &""


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_toggle.set_pressed(not _toggle.button_pressed)


func _on_toggled(vis: bool):
	toggled.emit(_toggle.button_pressed)


func _on_remove_pressed() -> void:
	remove_pressed.emit()
