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
		states.IDLE, states.FALL, states.RUN, states.JUMP:
			#In these states, you'll always calculate input, gravity, and physics.
			if parent.check_ground() != 0b11:
				parent.apply_gravity(delta)
			else:
				parent.Velocity.y = clamp(parent.Velocity.y, 0.0, INF)
			parent.calc_direction(delta)
			parent.apply_physics(delta)
	if state != states.DEAD:
		if is_network_master():
			GlobalCamera.transformoverride = parent.Head.global_transform

func _get_transition(delta):
	#Under what conditions should I change my state?
	match state:
		states.IDLE:
			if parent.direction:
				return states.RUN
			if parent.Velocity.y < 0 && (parent.check_ground() == 0b00):
				return states.FALL
		states.FALL:
			if parent.check_ground() == 0b11:
				if parent.direction.length() < 0.1:
					return states.IDLE
				else:
					return states.RUN
		states.RUN:
			if parent.check_ground() == 0b00:
				return states.FALL
			if parent.Velocity.length() < 1:
				return states.IDLE
		states.JUMP:
			if parent.check_ground() == 0b11:
				return states.IDLE
	return null

#Entering a state. Play an animation or something.
func _enter_state(new_state, old_state):
	match new_state:
		states.DEAD:
			if is_network_master():
				get_node("../HUD").visible = false
			get_node('../capsulecollider').disabled = true
			return

#Sometimes exitting a state should do something.
func _exit_state(old_state, new_state):
	match old_state:
		states.DEAD:
			if is_network_master():
				get_node("../HUD").visible = true
			get_node('../capsulecollider').disabled = false
			return
	pass
