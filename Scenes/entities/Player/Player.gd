extends KinematicBody
class_name Player

#Physics-related variables
var air_accel:float 	= 5.0
onready var base_air_accel:float = air_accel

var normal_accel:float 	= 8.0
var friction:float		= 16.0
var max_ground_speed:float 		= 10.0
var max_air_speed:float = 2.0
var direction:Vector3 	= Vector3()
var gravity:float		= 15.0
var jump_force:float 	= 9.0
var full_contact:bool 	= true
var Velocity:Vector3 	= Vector3() setget setVelocity, getVelocity
remote func setVelocity(newvelocity):
	Velocity = newvelocity
func getVelocity():
	return Velocity

var lastjumptime = 0.0;
var is_airjump = false;
var airtime = 0.0;
#health
var health : float = 100.0 setget setHealth
func setHealth(newhealth):
	#if server - sync health across all clients
	newhealth = clamp(newhealth, 0, 100)
	emit_signal('changeHealth', health, newhealth)
	health = newhealth
signal changeHealth(old, new)
signal Damage(old, new)
var spawn_invuln_time := 1.0
var invulnerable := false


#Weapon-selection references
var currentWeapon setget setCurrentWeapon
signal changeCurrentWeapon(old, new)
func setCurrentWeapon(new):
	var old = currentWeapon
	currentWeapon = new
	#Disconnect the old weapon.
	if old:
		old.queue_free()
		old.disconnect('spawnABullet', $projectiles, "add_child")
	#Connect weapon to spawn a bullet.
	currentWeapon.connect('spawnABullet', $projectiles, "add_child")
	Hand.add_child(currentWeapon)
	currentWeapon.set_network_master(get_tree().get_network_unique_id())
	emit_signal("changeCurrentWeapon", old, currentWeapon)

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
	if !get_tree().network_peer:
		Network.createClient('192.168.0.0', 0)
		set_network_master(get_tree().get_network_unique_id())
	yield(get_tree(), 'idle_frame')
	setHealth(health)
	setCurrentWeapon($Head/Holder.get_child(0))
	if is_network_master():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		$nametag.visible = false
		var wep = load('res://Scenes/weapons/bomb_launcher/BombLauncher.tscn').instance() if NetworkLobby.my_info.primary == 0 else load('res://Scenes/weapons/railgun/Railgun.tscn').instance()
		setCurrentWeapon(wep)
	else:
		$HUD.queue_free()
		$painvignette.queue_free()
		$nametag.text = NetworkLobby.player_info[get_network_master()].username

func _process(delta) -> void:
	if is_network_master():
		view_roll(delta)
	lastjumptime += delta


#These functions will be called by the Finite State Machine to determine behavior.
func _physics_process(delta) -> void:
	if is_network_master():
		direction = Vector3.ZERO
		FSM._state_logic(delta)
		$HUD/speeddisplay.text = "h-speed : " + str(Vector2(Velocity.x, Velocity.z).length())


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
	var snap = Vector3.DOWN if (Velocity.length() > 0.5 && Velocity.y <= 0) else Vector3.ZERO
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
		$HUD/debug.text = ("velocity " + str(Velocity) +
		"\ncollision normal " + str(normal) + 
		"\nis on floor " + str(is_on_floor()) +
		"\nray check" + str($FloorCheck.is_colliding()) +
		"\nlast normal " + str(lastnormal) + 
		"\nstate " + str(FSM.get_state()) + 
		"\nairtime " + str(airtime))

	var gc = check_ground()

	if gc >= 0b10: #ground, ground + ray, ray
		#On ground. Apply friction. Unless you're holding space, in which case you will be frictionless, but your control is limited.
		if is_airjump and lastjumptime < 0.1 and airtime > 0.5:
			jump()

		var cur_speed
		var add_speed
		wallbouncecount = 0
		airtime = 0.0

		Velocity = Velocity.move_toward(Vector3.ZERO, friction * delta)
		cur_speed = Vector2(Velocity.x,Velocity.z).dot(Vector2(direction.x, direction.z)) #?????
		add_speed = clamp(max_ground_speed - cur_speed, 0, max_ground_speed)
		horizontal = lerp(Velocity, Velocity + (add_speed * direction), normal_accel * delta)
		if col:
			horizontal = horizontal.slide(normal)
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
		if FSM.state == "DEAD":
				return

		if event.is_action_pressed('Jump'):
			if check_ground() > 0b00:
				jump()
				is_airjump = false
			else:
				if airtime < 0.5 && (FSM.state != "JUMP") && (Velocity.y <= 0.0):
					jump()
					is_airjump = false
				is_airjump = true
			lastjumptime = 0.0

		if(currentWeapon): #Check isn't required- but just in case.
			currentWeapon._InputFromPlayer(event)
		else:
			#There is never a case where currentWeapon should be null- print an error.
			printerr("Error! 'currentWeapon' not set.")
			push_error("Error! 'currentWeapon' not set.")

		if event is InputEventMouseMotion:
			#TODO - Change Player structure. This should only rotate the mesh, which should have a position node for the camera to inherit transforms from.
			rotation.y = fmod(rotation.y - event.relative.x * UserConfigs.aim_sens * get_process_delta_time(), 2*PI)
			Head.rotation.x -= event.relative.y * UserConfigs.aim_sens * get_process_delta_time()
			Head.rotation.x = clamp(Head.rotation.x, -PI/2, PI/2)

		if event is InputEventKey:
			if event.as_text() == "Control+K":
				#suicide
				Damage(50000, get_tree().get_network_unique_id())
				rpc("Damage", 50000, get_tree().get_network_unique_id())

func jump() -> void:
	FSM.set_state(FSM.states.JUMP)
	Velocity += (jump_force * $FloorCheck.get_collision_normal()) if $FloorCheck.is_colliding() else jump_force * Vector3.UP
	Velocity.y = max(jump_force, Velocity.y)
	$sounds/jumps.stream = $sounds.jump_sound
	$sounds/jumps.play()


remote func Damage(damage, dealer : int = -1, currentHealth : int = health) -> void:
	#-1 = no source(id) specified
	#various exit states
	
	# ////  CURRENT ISSUE
	# Not very secure in terms of cheats. Should preferrably have damage handled entirely on the server- currently it is handled both between client and server in a weird way.
	# leads to potential desyncs. leads to multi-hits. Buggin.
	
	if FSM.states[FSM.state] == FSM.states.DEAD:
		return
	if invulnerable:
		return

	#actual damaging
	emit_signal('Damage', currentHealth, currentHealth - damage)
	setHealth(currentHealth - damage)
	if (currentHealth - damage) <= 0:
		#Ur dead as far as im concerned (probably make it servercliented again as this is just cliyent but it should be synced)
		kill()
		$respawnTimer.start()
	else:
		if damage > 0.1:
			$sounds/hurt.pitch_scale = rand_range(0.95, 1.05)
			$sounds/hurt.unit_db = lerp(-10, 0, clamp(damage / 34, 0, 1))
			$sounds/hurt.stream = $sounds.hurt_sounds[randi()%$sounds.hurt_sounds.size()]
			$sounds/hurt.play()


var airstuntween : SceneTreeTween
remote func Stun(start_amt : float = 0.0, duration : float = 1.5) -> void:
	if airstuntween is SceneTreeTween:
		airstuntween.kill()
	airstuntween = get_tree().create_tween()
	airstuntween.set_trans(Tween.TRANS_CIRC)
	airstuntween.set_ease(Tween.EASE_IN)
	air_accel = start_amt
	airstuntween.tween_property(self, "air_accel", base_air_accel, duration)


remote func kill() -> void:
	#enter DEAD state
	$sounds/hurt.stream = $sounds.death_sounds[randi()%$sounds.death_sounds.size()]
	$sounds/hurt.unit_db = 0.0
	$sounds/hurt.pitch_scale = rand_range(0.99, 1.01)
	$sounds/hurt.play()
	$nametag.visible = false
	currentWeapon.stopShooting()
	FSM.set_state(FSM.states.DEAD)
	#spawn corpse/ragdoll, become invisible and intangible (or just move somewhere far away)
	#set camera's target to the spawned corpse's viewtarget node
	visible = false


func respawn() -> void:
	setHealth(100)
	Velocity = Vector3.ZERO
	global_transform.origin = GameFuncts.get_random_spawnpoint().global_transform.origin
	FSM.set_state(FSM.states.IDLE)
	visible = true
	if !is_network_master():
		$nametag.visible = true
	invulnerable = true
	if is_network_master():
		$painvignette.ouchiness = 1.0;
		$painvignette.damagetween.kill()
	yield(get_tree().create_timer(spawn_invuln_time), 'timeout')
	invulnerable = false


remote func syncPosition(transforms, vel, input):
	#Server - Update the locally stored position of the player. Notify all of the other players.
	global_transform = transforms
	Velocity = vel
	direction = input
	if get_tree().is_network_server():
		#if you are the server, notify everyone except the sender about their position
		for i in get_tree().get_network_connected_peers():
			if i != get_tree().get_rpc_sender_id():
				rpc_unreliable_id(i, "syncPosition", global_transform, Velocity, direction)


func _on_networktick_timeout() -> void:
	if is_network_master() and get_tree().get_network_connected_peers().size() > 0:
		#Tell the server your new location, it will sync to the other clients
		if !get_tree().is_network_server():
			rpc_unreliable_id(1, "syncPosition", global_transform, Velocity, direction)
		else:
			syncPosition(global_transform, Velocity, direction)


func _on_respawnTimer_timeout() -> void:
	respawn()
