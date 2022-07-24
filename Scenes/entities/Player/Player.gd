extends KinematicBody
class_name Player

#Physics-related variables
var air_accel:float 	= 5.0
var normal_accel:float 	= 8.0
var friction:float		= 16.0
var max_ground_speed:float 		= 10.0
var max_air_speed:float = 2.5
var direction:Vector3 	= Vector3()
var gravity:float		= 15.0
var jump_force:float 	= 8.0
var full_contact:bool 	= true
var Velocity:Vector3 	= Vector3()

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
master var primary;
master var secondary;

#References to nodes for simplification
onready var ground_check = $FloorCheck
onready var Head = $Head
onready var Hand = $Head/Holder
onready var hand_default_Pos : Vector3 = Hand.translation
onready var FSM = $StateMachine

func _ready():
	if is_network_master():
		setHealth(health)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		currentWeapon = $Head/Holder.get_child(0)
	else:
		$UI.queue_free()

func _process(delta):
	#Test Options Menu
#	if Input.is_action_pressed("pause"):
#		Options.popup_centered()
#		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if is_network_master():
		view_roll(delta)

#These functions will be called by the Finite State Machine to determine behavior.
func _physics_process(delta):
	if is_network_master():
		direction = Vector3.ZERO
		FSM._state_logic(delta)
		$UI/speeddisplay.text = "h-speed : " + str(Vector2(Velocity.x, Velocity.z).length())

#Tilts camera based on input.
func view_roll(delta):
	if is_network_master():
		if UserConfigs.is_view_roll:
			var rotation_speed : float = max_ground_speed * delta
			var roll_amount : int = 2
			var angle : float = roll_amount * (int(Input.is_action_pressed("MoveRight")) + -int(Input.is_action_pressed("MoveLeft")))
			Head.rotation.z = lerp(Head.rotation.z, -deg2rad(angle), rotation_speed)

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
	if is_network_master():
		direction -= transform.basis.z * Input.get_action_strength('MoveForward')
		direction += transform.basis.z * Input.get_action_strength('MoveBackward')
		direction -= transform.basis.x * Input.get_action_strength('MoveLeft')
		direction += transform.basis.x * Input.get_action_strength('MoveRight')
		direction = direction.normalized()

#Applies the physics- just does move_and_slide.
func apply_physics(delta):
	#Applies physics. Typically called last.
	#Apply friction first.
	
	var horizontal = Vector3.ZERO
	if check_ground() > 0b00:
		#On ground. Apply friction
		Velocity = Velocity.move_toward(Vector3.ZERO, friction * delta)
		
		var cur_speed = Vector2(Velocity.x,Velocity.z).dot(Vector2(direction.x, direction.z))
		var add_speed = clamp(max_ground_speed - cur_speed, 0, max_ground_speed)
		horizontal = lerp(Velocity, Velocity + (add_speed * direction), normal_accel * delta)
	else:
		#Player is airborne. Do air physics.
		var cur_speed = Vector2(Velocity.x,Velocity.z).dot(Vector2(direction.x, direction.z))
		var add_speed = clamp(max_air_speed - cur_speed, 0, max_ground_speed)
		horizontal = lerp(Velocity, Velocity + (add_speed * direction), air_accel * delta)
	Velocity.z = horizontal.z
	Velocity.x = horizontal.x
	#After doing that movement stuff, check for collisions with ground and adjust to match slope
	move_and_slide(Velocity, Vector3.UP)

#Useful for things that sort of override other effects.
func _unhandled_input(event: InputEvent) -> void:
	if is_network_master():
		if event.is_action_pressed('Jump') and full_contact:
			Velocity.y = jump_force
		
		if event.is_action_pressed("fire"):
			if(currentWeapon): #Check isn't required- but just in case.
				if is_network_master():
					currentWeapon.rpc("shoot")
					currentWeapon.shoot()
			else:
				#There is never a case where currentWeapon should be null- print an error.
				printerr("Error! 'currentWeapon' not set.")
				push_error("Error! 'currentWeapon' not set.")
		
		if event is InputEventMouseMotion:
			#TODO - Change Player structure. This should only rotate the mesh, which should have a position node for the camera to inherit transforms from.
			rotation.y = fmod(rotation.y - event.relative.x * UserConfigs.aim_sens * get_process_delta_time(), 2*PI)
			Head.rotation.x -= event.relative.y * UserConfigs.aim_sens * get_process_delta_time()
			Head.rotation.x = clamp(Head.rotation.x, -PI/2, PI/2)

func Damage(damage):
	setHealth(health - damage)
	if health <= 0:
		kill()

func kill():
	queue_free()

remote func syncPosition(transforms, vel, input):
	global_transform = transforms
	Velocity = vel
	direction = input
	pass

func _on_networktick_timeout() -> void:
	if is_network_master():
		rpc_unreliable("syncPosition", global_transform, Velocity, direction)
	pass # Replace with function body.
