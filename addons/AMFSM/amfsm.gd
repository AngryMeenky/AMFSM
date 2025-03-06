@icon("res://addons/AMFSM/icons/FSM.svg")
extends Node
class_name AMFiniteStateMachine


signal errored(fsm: AMFiniteStateMachine)
signal completed(fsm: AMFiniteStateMachine)
signal state_changed(fsm: AMFiniteStateMachine, from: StringName, to: StringName)


const START := &"Start"
const FINAL := &"Final"
const ERROR := &"Error"
const _NIL_CALL := Callable()


var _states := {}
var _current: State = null
var _transitioning := false

@export var resolve_root: NodePath = ^"."
@export var states: Array[Dictionary] = [
	{ "name": START },
	{ "name": ERROR },
	{ "name": FINAL },
]


func _ready() -> void:
	var root := get_node(resolve_root)
	if root == null:
		printerr("Unable to locate node for NodePath resolution: ", resolve_root)
		return

	# make sure all the states exist
	for state in states:
		_states[state.name] = State.make(self, state["name"])
	# now add in all the transitions
	for state in states:
		unpack(root, state)


func is_errored() -> bool:
	return _current.name == ERROR


func is_completed() -> bool:
	return _current.name == FINAL


func get_state() -> StringName:
	return _current.name


func add_state(state: StringName) -> void:
	assert(state not in _states, "Attempt to add a duplicate state")
	states.append(State.make(self, state))
	_states[state] = states.back()


func remove_state(name: StringName) -> void:
	assert(name in _states, "Attempt to remove a non-existant state")
	var state = _states[name]
	assert(state.removable, "Can't remove basic state: %s" % name)
	
	for src in state.incoming.keys():
		var from: State = _states[src]
		for trigger in state.incoming[src].duplicate():
			from.remove_transition(trigger)

	_states.erase(name)
	states.erase(state)


func add_callbacks(state: StringName, enter = _NIL_CALL, stay = _NIL_CALL, exit = _NIL_CALL) -> void:
	assert(state in _states, "Attempt to update a non-existant state")
	_states[state].add_callbacks(enter, stay, exit)


func remove_callbacks(state: StringName, enter = _NIL_CALL, stay = _NIL_CALL, exit = _NIL_CALL) -> void:
	assert(state in _states, "Attempt to update a non-existant state")
	_states[state].remove_callbacks(enter, stay, exit)


func add_transition(from: StringName, trigger: StringName, to: StringName) -> void:
	assert(from in _states, "Can't transition from a non-existant state")
	assert(to in _states, "Can't transition to a non-existant state")
	_states[from].add_transition(trigger, to)


func remove_transition(from: StringName, trigger: StringName) -> void:
	assert(from in _states, "Can't transition from a non-existant state")
	_states[from].remove_transition(trigger)


func update(trigger: StringName) -> StringName:
	assert(not _transitioning, "Can't update FSM during an update")
	_transitioning = true
	var next := _current.get_target(trigger)
	if next == _current:
		next.stay()
	else:
		var old := _current.name
		_current.exit()
		_current = next
		next.enter()
		state_changed.emit(self, old, next.name)
		if next.name == FINAL:
			completed.emit(self)
	_transitioning = false
	# be loud about the errored state
	if _current.name == ERROR:
		errored.emit(self)
	return next.name


func reset() -> void:
	assert(not _transitioning, "Can't reset FSM during an update")
	if _current.name != START:
		var old := _current.name
		_current.exit()
		_current = _states[START]
		_current.enter()
		state_changed.emit(self, old, START)


func _resolve_callback(np: NodePath) -> Callable:
	if np == ^"":
		return Callable()
	assert(np.get_subname_count() == 1, "NodePath only specifies a Node: %s" % np)
	return Callable(get_node(resolve_root).get_node(np), np.get_subname(0))


func unpack(root: Node, data: Dictionary) -> void:
	# grab the correct state
	var state = _states[data["name"]]
	
	# add in all the transitions
	var transitions: Dictionary = data.get("transitions", {})
	for trigger in transitions.keys():
		state.add_transition(trigger, transitions[trigger])

	# connect all the callbacks
	var enter: Array = data.get("enter", [])
	var stay:  Array = data.get("stay",  [])
	var exit:  Array = data.get("exit",  [])
	var count: int = max(enter.size(), stay.size(), exit.size())
	for idx in count:
		state.add_callbacks(
			_resolve_callback(NodePath(enter[idx]) if idx < enter.size() else ^""),
			_resolve_callback(NodePath(stay[idx])  if idx < stay.size()  else ^""),
			_resolve_callback(NodePath(exit[idx])  if idx < exit.size()  else ^"")
		)

#func pack(root: Node, state: State) -> Dictionary:
#	return {} # TODO: perform the packing


class State extends RefCounted:
	signal on_enter(fsm: AMFiniteStateMachine, state: StringName)
	signal on_stay(fsm: AMFiniteStateMachine, state: StringName)
	signal on_exit(fsm: AMFiniteStateMachine, state: StringName)

	var name := &""
	var incoming := {}
	var transitions := {}
	var removable := true
	var host: AMFiniteStateMachine = null


	static func make(parent: AMFiniteStateMachine, name: StringName) -> State:
		var state = State.new()
		state.name = name
		match name:
			ERROR, FINAL:
				state.transitions.make_read_only()
				state.removable = false
			START:
				state.removable = false
		return state


	func add_callbacks(enter: Callable, stay := Callable(), exit := Callable()) -> void:
		if enter.is_valid():
			on_enter.connect(enter)
		if stay.is_valid():
			on_stay.connect(stay)
		if exit.is_valid():
			on_exit.connect(exit)


	func remove_callbacks(enter: Callable, stay := Callable(), exit := Callable()) -> void:
		if enter.is_valid():
			on_enter.disconnect(enter)
		if stay.is_valid():
			on_stay.disconnect(stay)
		if exit.is_valid():
			on_exit.disconnect(exit)


	func add_transition(trigger: StringName, state: StringName) -> void:
		assert(trigger not in transitions, "Transition trigger already assigned")
		assert(not transitions.is_read_only(), "Attempt to modify a terminal state")

		var target: State = host._states[state]
		transitions[trigger] = target
		if name not in target.incoming:
			target.incoming[name] = []
		target.incoming[name].append(trigger)


	func remove_transition(trigger: StringName) -> void:
		assert(trigger in transitions, "Can't remove non-existant transition trigger")
		var target: State = transitions[trigger]
		var list: Array = target.incoming[name]
		list.erase(trigger)
		if list.is_empty():
			target.incoming.erase(name)
		transitions.erase(trigger)


	func get_target(trigger: StringName) -> State:
		return transitions.get(trigger, host._states[ERROR])


	func enter() -> void:
		on_enter.emit(host, name)


	func stay() -> void:
		on_stay.emit(host, name)


	func exit() -> void:
		on_exit.emit(host, name)
