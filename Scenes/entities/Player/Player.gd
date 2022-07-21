extends KinematicBody
class_name Player

#Physics-related variables
var air_accel:float 	= 1.0
var normal_accel:float 	= 8.0
var speed:float 		= 10.0
var direction:Vector3 	= Vector3()
var gravity:float		= 15.0
var jump_force:float 	= 8.0
var full_contact:bool 	= true
var Velocity:Vector3 	= Vector3()
var time:float			= 0.0

#health
var health = 100 setget setHealth
func setHealth(newhealth):
	newhealth = clamp(newhealth, 0, 100)
	emit_signal('changeHealth', health, newhealth)
	health = newhealth
signal changeHealth(old, new)

#Weapon-selection references
var currentWeapon
#Hard-coding primary and secondary weapons, as it is all that the gameplay requires.
var primary;
var secondary;

#References to nodes for simplification
onready var aimcast = $Head/Camera/AimCast
onready var ground_check = $FloorCheck
onready var Head = $Head
onready var camera = $Head/Camera
onready var Reach = $Head/Camera/Reach
onready var Hand = $Head/Holder
onready var hand_default_Pos : Vector3 = Hand.translation
onready var anim_player = $AnimationPlayer
onready var FSM = $StateMachine

func _ready():
	setHealth(health)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	currentWeapon = $Head/Holder.get_child(0)

func _process(delta):
	view_roll(delta)

#These functions will be called by the Finite State Machine to determine behavior.
func _physics_process(delta):
	direction = Vector3.ZERO
	FSM._state_logic(delta)
	time += delta

#Tilts camera based on input.
func view_roll(delta):
	var rotation_speed : float = speed * delta
	var roll_amount : int = 2
	var angle : float = roll_amount * (int(Input.is_action_pressed("MoveRight")) + -int(Input.is_action_pressed("MoveLeft")))
	camera.rotation.z = lerp(camera.rotation.z, -deg2rad(angle), rotation_speed)

#Checks if colliding with ground, returns flags based on results.
func check_ground() -> int:
	if ground_check.is_colliding():
		full_contact = true
	else:
		full_contact = false
	#return 2 bits - first bit is_on_floor(), second full_contact
	return int(is_on_floor()) + (int(full_contact) << 1)

#Applies gravity.
func apply_gravity(delta):
	Velocity.y -= gravity * delta

#Calculates movement direction of input.
func calc_direction(delta):
	direction -= transform.basis.z * Input.get_action_strength('MoveForward')
	direction += transform.basis.z * Input.get_action_strength('MoveBackward')
	direction -= transform.basis.x * Input.get_action_strength('MoveLeft')
	direction += transform.basis.x * Input.get_action_strength('MoveRight')
	direction = direction.normalized()

#Applies the physics- just does move_and_slide.
func apply_physics(delta):
	#Applies physics. Typically called last.
	#Get the horizontal component of movement.
	var h_accel = normal_accel if check_ground() > 0b00 else air_accel
	var horizontal = Velocity.linear_interpolate(direction * speed, h_accel * delta)
	Velocity.z = horizontal.z
	Velocity.x = horizontal.x
	
	move_and_slide(Velocity, Vector3.UP)

#Useful for things that sort of override other effects.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('Jump') and full_contact:
		Velocity.y = jump_force
	if event.is_action_pressed("fire"):
		if(currentWeapon): #Check isn't required- but just in case.
			currentWeapon.shoot()
		else:
			#There is never a case where currentWeapon should be null- print an error.
			printerr("Error! 'currentWeapon' not set.")
			push_error("Error! 'currentWeapon' not set.")
	
	if event is InputEventMouseMotion:
		#TODO - Change Player structure. This should only rotate the mesh, which should have a position node for the camera to inherit transforms from.
		rotate_y(deg2rad(-event.relative.x * UserConfigs.aim_sens))
		Head.rotate_x(deg2rad(-event.relative.y * UserConfigs.aim_sens))
		Head.rotation.x = clamp(Head.rotation.x, deg2rad(-89), deg2rad(89))
	
	if event.is_action_pressed("action"):
		var rng = RandomNumberGenerator.new()
		pass

func Damage(damage):
	setHealth(health - damage)
	if health <= 0:
		kill()

func kill():
	queue_free()
