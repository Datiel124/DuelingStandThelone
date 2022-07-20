extends KinematicBody


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"

#Physics-related variables
var velocity : Vector3 = Vector3.ZERO
export var gravity = 10.0
export var bounciness = 0.6
onready var animplayer = $AnimationPlayer
onready var FSM = $StateMachine

#Turret damage and cooldown
var damage = 1;
var cooldown = 0.1;
var delay = 0.5;

var isGrounded = false
# Called when the node enters the scene tree for the first time.
func _physics_process(delta: float) -> void:
	pass

func apply_gravity(delta):
	velocity.y -= gravity * delta
func apply_physics():
	var col = move_and_collide(velocity)
	if col.normal.dot(Vector3.UP) < 0.5:
		velocity = velocity.bounce(col.normal) * bounciness
	else:
		$StateMachine._enter_state($StateMachine.states.DEPLOY)

func deploy(groundnormal):
	look_at(global_transform.origin + groundnormal, Vector3.UP)
	pass

func attackTarget(target : Player):
	#Deal damage to the target.
	#Visibility check should have been done before this.
	target.Damage(damage)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
