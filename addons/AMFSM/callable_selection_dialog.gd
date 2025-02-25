@tool
extends ConfirmationDialog
class_name CallableSelectionDialog


const _PROTOS := {
	"enter": {
		"name": "enter",
		"args": [
			{"name": "fsm",  "type": TYPE_OBJECT, "class_name": "FiniteStateMachine"},
			{"name": "state", "type": TYPE_STRING_NAME}
		],
		"return": { "type": TYPE_NIL }
	 },
	"stay": {
		"name": "stay",
		"args": [
			{"name": "fsm",  "type": TYPE_OBJECT, "class_name": "FiniteStateMachine"},
			{"name": "state", "type": TYPE_STRING_NAME}
		],
		"return": { "type": TYPE_NIL }
	},
	"exit": {
		"name": "exit",
		"args": [
			{"name": "fsm",  "type": TYPE_OBJECT, "class_name": "FiniteStateMachine"},
			{"name": "state", "type": TYPE_STRING_NAME}
		],
		"return": { "type": TYPE_NIL }
	},
}

const _TYPE_NAMES: Array[StringName] = [
	&"void",               &"bool",              &"int",
	&"float",              &"String",            &"Vector2",
	&"Vector2i",           &"Rect2",             &"Rect2i",
	&"Vector3",            &"Vector3i",          &"Transform2D",
	&"Vector4",            &"Vector4i",          &"Plane",
	&"Quaternion",         &"AABB",              &"Basis",
	&"Transform3D",        &"Projection",        &"Color",
	&"StringName",         &"NodePath",          &"RID",
	&"Object",             &"Callable",          &"Signal",
	&"Dictionary",         &"Array",             &"PackedByteArray",
	&"PackedInt32Array",   &"PackedInt64Array",  &"PackedFloat32Array",
	&"PackedFloat64Array", &"PackedStringArray", &"PackedVector2Array",
	&"PackedVector3Array", &"PackedColorArray",  &"PackedVector4Array",
]


@onready var scene_tree := $HBox/Simple/SceneTree as Tree
@onready var filter := $HBox/Simple/HBox/Filter as LineEdit
@onready var proto_display := $HBox/Simple/Prototype as LineEdit
@onready var receiver := $HBox/Simple/Receiver/MethodName as LineEdit

var prototype := {}
var scene_root: Node = null
var shadow_dom: TreeItem = null
var source_node: TreeItem = null


func activate(fsm: FiniteStateMachine, action: StringName, state: StringName, scene: Node) -> void:
	set_callable_name("_on_%s_%s_%s" % [
		fsm.name.to_snake_case(), action, state.to_snake_case()
	])
	set_prototype(_PROTOS[action])
	set_scene_root(scene, fsm)
	filter.clear()
	show()


func set_callable_name(callable_name: String) -> void:
	receiver.text = callable_name


func set_scene_root(scene: Node, fsm: FiniteStateMachine) -> void:
	assert(scene != null, "Scene root must not be null")
	scene_root = scene
	scene_tree.clear()
	scene_tree.set_column_expand(0, true)
	scene_tree.set_column_expand(1, false)

	shadow_dom = scene_tree.create_item()
	shadow_dom.set_text(0, scene.name)
	shadow_dom.set_icon(0, _resolve_icon(scene))
	if scene.get_script() != null:
		shadow_dom.set_icon(1,EditorInterface.get_editor_theme().get_icon(&"Script", &"EditorIcons"))
		if scene == fsm:
			source_node = shadow_dom
	for child in scene.get_children():
		_add_child_to_tree(shadow_dom, child, fsm)


func set_prototype(proto: Dictionary) -> void:
	prototype = proto.duplicate()
	proto_display.editable = true
	proto_display.text = "func %s(%s) -> %s" % [
		proto["name"], _stringify_arg_list(proto["args"]), _stringify_type(proto["return"])
	]
	proto_display.editable = false


func get_prototype() -> Dictionary:
	return prototype


func _add_child_to_tree(parent: TreeItem, child: Node, fsm: FiniteStateMachine) -> void:
	var item := parent.create_child()
	item.set_text(0, child.name)
	item.set_icon(0, _resolve_icon(child))
	if child.get_script() != null:
		item.set_icon(1,EditorInterface.get_editor_theme().get_icon(&"Script", &"EditorIcons"))
		if child == fsm:
			source_node = item
	for grandchild in child.get_children():
		_add_child_to_tree(item, grandchild, fsm)


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


func _stringify_arg_list(args: Array) -> String:
	match args.size():
		0:
			return ""
		1:
			return _stringify_arg(args[0])
		_:
			var list: PackedStringArray = []
			for arg in args:
				list.append(_stringify_arg(arg))
			return ", ".join(list)


func _stringify_arg(arg: Dictionary) -> String:
	return "%s: %s" % [ arg["name"], _stringify_type(arg) ]


func _stringify_type(type: Dictionary) -> StringName:
	var idx: int = type["type"]
	if idx >= 0 and idx < _TYPE_NAMES.size():
		if idx == TYPE_OBJECT:
			var cls_nam: StringName = type["class_name"]
			return cls_nam if cls_nam else &"Object"
		if idx == TYPE_ARRAY:
			print(type["class_name"])
		return _TYPE_NAMES[idx]
	printerr("Invalid type enum: ", idx)
	return "INVALID TYPE ENUM"


func _on_source_pressed() -> void:
	scene_tree.set_selected(source_node, 0)
	scene_tree.scroll_to_item(source_node)


func _on_filter_changed(new_text: String) -> void:
	#TODO: change the visibility of the nodes based on the new_text
	pass
