@tool
extends ConfirmationDialog
class_name CallableSelectionDialog


@onready var scene_tree := $HBox/Simple/SceneTree as Tree
@onready var receiver := $HBox/Simple/Receiver/MethodName as LineEdit

var scene_root: Node = null


func set_callable_name(callable_name: String) -> void:
	receiver.text = callable_name


func set_scene_tree(scene: Node) -> void:
	scene_tree.clear()
	scene_tree.set_column_expand(0, true)
	scene_tree.set_column_expand(1, false)

	var root := scene_tree.create_item()
	root.set_text(0, scene.name)
	root.set_icon(0, _resolve_icon(scene))
	if scene.get_script() != null:
		root.set_icon(1,EditorInterface.get_editor_theme().get_icon(&"Script", &"EditorIcons"))
	for child in scene.get_children():
		_add_child_to_tree(root, child)


func _add_child_to_tree(parent: TreeItem, child: Node) -> void:
	var item := parent.create_child()
	item.set_text(0, child.name)
	item.set_icon(0, _resolve_icon(child))
	if child.get_script() != null:
		item.set_icon(1,EditorInterface.get_editor_theme().get_icon(&"Script", &"EditorIcons"))
	for grandchild in child.get_children():
		_add_child_to_tree(item, grandchild)


func _resolve_icon(node: Node) -> Texture2D:
	var script = node.get_script()
	if script != null:
		var global: StringName = script.get_global_name()
		if not global.is_empty():
			for entry in ProjectSettings.get_global_class_list():
				if entry["class"] == global:
					if not entry["icon"].is_empty():
						return load(entry["icon"])
					break
	return EditorInterface.get_editor_theme().get_icon(node.get_class(), &"EditorIcons")
