extends StateMachine

onready var parent = get_parent()
onready var anim = get_node("../AnimationPlayer")

func _ready() -> void:
	add_state("AIR")
	add_state("DEPLOY")
	add_state("SEARCH")
	add_state("ATTACK")

# Called when the node enters the scene tree for the first time.
func _state_logic(delta):
	match state:
		states.AIR:
			#fly through the air gracefully
			parent.apply_gravity() 
			parent.apply_physics()
			pass
		states.SEARCH:
			pass
		states.ATTACK:
			pass
		_:
			pass

func _enter_state(new_state, old_state):
	match new_state:
		states.DEPLOY:
			#Play the DEPLOY animation, do other startup things
			parent.deploy()
			pass
		states.SEARCH:
			#Search for the enemy. Set animation to SPIN if it isn't already playing.
			if anim.current_animation != "spin":
				anim.stop()
				anim.play('spin')
			pass
		states.ATTACK:
			#Get ready to attack the enemy. Start up that timer.
			if anim.current_animation != "spin":
				anim.stop()
				anim.play('spin')
			$attackdelay.start(0.5)
			pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
