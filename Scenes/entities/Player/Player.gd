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

var lastjumptime = 0.0;
var is_airjump = false;
var airtime = 0.0;
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

func _ready() -> void:
	if is_network_master():
		setHealth(health)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		currentWeapon = $Head/Holder.get_child(0)
	else:
		$UI.queue_free()

func _process(delta) -> void:
	if is_network_master():
		view_roll(delta)
	lastjumptime += delta

#These functions will be called by the Finite State Machine to determine behavior.
func _physics_process(delta) -> void:
	if is_network_master():
		direction = Vector3.ZERO
		FSM._state_logic(delta)
		$UI/speeddisplay.text = "h-speed : " + str(Vector2(Velocity.x, Velocity.z).length())

#Tilts camera based on input.
func view_roll(delta) -> void:
	if is_network_master():
		if UserConfigs.is_view_roll:
			var rotation_speed : float = max_ground_speed * delta
			var roll_amount : int = 2
			var angle : float = roll_amount * (int(Input.is_action_pressed("MoveRight")) + -int(Input.is_action_pressed("MoveLeft")))
			Head.rotation.z = lerp(Head.rotation.z, -deg2rad(angle), rotation_speed)

#Checks if colliding with ground, returns flags based on results.
func check_ground() -> int:
	test_move(transform, Vector3.ZERO)
	if ground_check.is_colliding():
		full_contact = true
	else:
		full_contact = false
	#return 2 bits - first bit is_on_floor(), second full_contact
	return int(is_on_floor()) + (int(full_contact) << 1)

#Applies gravity.
func apply_gravity(delta) -> void:
	Velocity.y -= gravity * delta
	if check_ground() == 0b00:
		airtime += delta
	else:
		airtime = 0.0

#Calculates movement direction of input.
func calc_direction(delta) -> Vector3:
	#Client - calcualte movement trajectory based on input
	if is_network_master():
		direction -= transform.basis.z * Input.get_action_strength('MoveForward')
		direction += transform.basis.z * Input.get_action_strength('MoveBackward')
		direction -= transform.basis.x * Input.get_action_strength('MoveLeft')
		direction += transform.basis.x * Input.get_action_strength('MoveRight')
		direction = direction.normalized()
	return direction

#Applies the physics- just does move_and_slide.
var lastnormal = Vector3.ZERO
var wallbouncecount = 0.0
func apply_physics(delta) -> void:
	var snap = Vector3.DOWN if Velocity.y <= 0 else Vector3.ZERO
	move_and_slide_with_snap(Velocity, snap, Vector3.UP)
	#Applies physics. Typically called last.
	#Apply friction first.

	var horizontal = Vector3.ZERO
	#valid values = 0b11, 0b01
	var col = null
	if get_slide_count() > 0: 
		col = get_slide_collision(0)
	var normal = col.normal if col else "---"
	if col:
		lastnormal = normal
		if normal.dot(Vector3.UP) > 0.9: # 0.9 high sameness
			normal = Vector3.UP
		if normal.dot(Vector3.DOWN) > 0.9: # 0.9 high sameness
			normal = Vector3.DOWN
	if is_network_master():
		$UI/debug.text = ("collision normal " + str(normal) + 
		"\nis on floor " + str(is_on_floor()) +
		"\nray check" + str($FloorCheck.is_colliding()) +
		"\nlast normal " + str(lastnormal) + 
		"\nstate " + str(FSM.get_state()) + 
		"\nairtime " + str(airtime))
	var gc = check_ground()
	if gc >= 0b01: #ground, ground + ray, ray
		#On ground. Apply friction. Unless you're holding space, in which case you will be frictionless, but your control is limited.
		var cur_speed
		var add_speed
		wallbouncecount = 0
		airtime = 0.0
		if !Input.is_action_pressed('Jump'):
			Velocity = Velocity.move_toward(Vector3.ZERO, friction * delta)
			cur_speed = Vector2(Velocity.x,Velocity.z).dot(Vector2(direction.x, direction.z)) #?????
			add_speed = clamp(max_ground_speed - cur_speed, 0, max_ground_speed)
			horizontal = lerp(Velocity, Velocity + (add_speed * direction), normal_accel * delta)
			if col:
				horizontal = horizontal.slide(normal)
		else:
			var downhill = (Vector3.DOWN * gravity).bounce(get_floor_normal())
			horizontal = Velocity + (downhill * delta)
	else:
		#Player is airborne. Do air physics.
		var cur_speed = Vector2(Velocity.x,Velocity.z).dot(Vector2(direction.x, direction.z))
		var add_speed = clamp(max_air_speed - cur_speed, 0, max_ground_speed)
		horizontal = lerp(Velocity, Velocity + (add_speed * direction), air_accel * delta)

	Velocity.z = horizontal.z
	Velocity.x = horizontal.x
	if col and gc == 0b00:
		if is_airjump and lastjumptime < 0.5:
			#preform a wallbounce
			var newbounce = $sounds/jumps.duplicate()
			$sounds/stationary.add_child(newbounce)
			newbounce.global_transform = global_transform
			newbounce.unit_db = 0
			newbounce.stream = $sounds.wallbounce_sound
			newbounce.play()
			wallbouncecount += 1
			#clamp the wallbounce angle to be 45 degrees from the normal at most, based on input. 1.25x Velocity bonus.
			var bounceoff = normal * min(Velocity.length() * (1.25 if (wallbouncecount == 1 || Velocity.length() > 16) else 1.0), 16)
			Velocity = Vector3(bounceoff.x, max(0.0, Velocity.y + (jump_force if wallbouncecount == 1 else 0)), bounceoff.z)
			is_airjump = false
		else:
			#hit the wall and lose speed in the direction of the wall
			if col:
				Velocity = Velocity.slide(normal)

#Useful for things that sort of override other effects.
func _unhandled_input(event: InputEvent) -> void:
	if is_network_master():
		if event.is_action_pressed('Jump'):
			if check_ground() > 0b00:
				FSM.set_state(FSM.states.JUMP)
				Velocity.y = jump_force
				$sounds/jumps.stream = $sounds.jump_sound
				$sounds/jumps.play()
				is_airjump = false
			else:
				if airtime < 0.5 && (FSM.state != "JUMP") && (Velocity.y <= 0.0):
					#user has been airborn for a short period of time, do coyotetime jump	
					Velocity.y = jump_force
					$sounds/jumps.stream = $sounds.jump_sound
					$sounds/jumps.play()
					is_airjump = false
				is_airjump = true
			lastjumptime = 0.0
		
		if event.is_action_pressed("fire"):
			if(currentWeapon): #Check isn't required- but just in case.
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

remote func Damage(damage, dealer : int = -1) -> void:
	#-1 = no source specified
	setHealth(health - damage)
	if health <= 0:
		#Ur dead as far as im concerned (probably make it servercliented again as this is just cliyent but it should be synced)
		kill()
		$respawnTimer.start()

remote func kill() -> void:
	#enter DEAD state
	FSM.set_state(FSM.states.DEAD)
	#spawn corpse/ragdoll, become invisible and intangible (or just move somewhere far away)
	#set camera's target to the spawned corpse's viewtarget node

func respawn() -> void:
	setHealth(100)
	Velocity = Vector3.ZERO
	global_transform.origin = GameFuncts.get_random_spawnpoint().global_transform.origin

remote func syncPosition(transforms, vel, input):
	#sync the position
	global_transform = transforms
	Velocity = vel
	direction = input

func _on_networktick_timeout() -> void:
	if is_network_master() and get_tree().get_network_connected_peers().size() > 0:
		#Tell the server your new location, it will sync to the other clients
		rpc_unreliable("syncPosition", global_transform, Velocity, direction)


func _on_respawnTimer_timeout() -> void:
	respawn()
