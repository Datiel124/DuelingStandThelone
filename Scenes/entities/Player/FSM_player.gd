extends StateMachine

onready var parent = get_parent()
#onready var anim = get_node("../AnimationPlayer")

func _ready() -> void:
	#IDLE state. Not moving, just standing still. Check for movement.
	add_state("IDLE")
	#RUN state. Player is running about.
	add_state("RUN")
	#JUMP state. The player initiated a jump.
	add_state("JUMP")
	#FALL state. The player is now falling downwards.
	add_state("FALL")
	#STUN state. The player was stunned.
	add_state("STUN")
	#DEAD state. The player is dead.
	add_state("DEAD")
	set_state(states.IDLE)

func _state_logic(delta):
	match state:
		states.IDLE, states.FALL, states.RUN:
			#In these states, you'll always calculate input, gravity, and physics.
			if parent.check_ground() == 0b00:
				parent.apply_gravity(delta)
			else:
				parent.Velocity.y = clamp(parent.Velocity.y, 0.0, INF)
			parent.calc_direction(delta)
			parent.apply_physics(delta)

func _get_transition(delta):
	#Under what conditions should I change my state?
	return null

#Entering a state. Play an animation or something.
func _enter_state(new_state, old_state):
	match new_state:
		_:
			return

#Sometimes exitting a state should do something.
func _exit_state(old_state, new_state):
	pass
