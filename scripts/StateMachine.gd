extends Node
class_name StateMachine, 'res://DEV/icon_statemachine.png'

#keep track of state we're currently in
var state  = null setget set_state
var previous_state = null
var states = {}

func _physics_process(delta: float) -> void:
	if state != null:
		_state_logic(delta)
		var transition = _get_transition(delta)
		if transition != null:
			set_state(transition)

##################################################
#COPY THESE TO ANY SCRIPT INHERITING THIS BASE!!!# vvv
##################################################

func _state_logic(delta): #called in physics process, meant to be overwritten with logic.
	pass

func _get_transition(delta):
	return null

func _enter_state(new_state, old_state): #common for setting animation, or starting tweens/timers.
	pass

func _exit_state(old_state, new_state):
	pass

##################################################
#COPY THESE TO ANY SCRIPT INHERITING THIS BASE!!!#  ^^^
##################################################

func set_state(new_state):
	previous_state = state
	state = new_state
	if previous_state != null: 
		_exit_state(previous_state, new_state)
	if new_state != null:
		_enter_state(new_state, previous_state)

func add_state(state_name):
	states[state_name] = states.size()
