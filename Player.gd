extends KinematicBody



var air_accel = 1
var normal_accel = 12
var speed = 13
var direction = Vector3()
var horiz_accel = 9
var gravity = 30
var jump_force = 10.5
var grav_vec = Vector3()
var full_contact = true
var wep_selected = 0
var health = 50

var horiz_velocity = Vector3()
var movement = Vector3()

var reserveAmmo : int
var MouseSens = 0.13

var shotgunAmmo : int
var PistolAmmo : int


onready var aimcast = $Head/Camera/AimCast
onready var ground_check = $FloorCheck
onready var Head = $Head
onready var camera = $Head/Camera
onready var Reach = $Head/Camera/Reach
onready var Hand = $Head/Holder
onready var anim_player = $AnimationPlayer


func view_roll(delta):
	var rotation_speed : float = speed * delta
	
	var angle : float = 2 * int(Input.is_action_pressed("MoveRight")) + - int(Input.is_action_pressed("MoveLeft"))
	
	camera.rotation.z = lerp(camera.rotation.z, -deg2rad(angle), rotation_speed)



func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	

func weapon_change():
	if Input.is_action_pressed("item1"):
		wep_selected = 1
	if Input.is_action_pressed("item2"):
		wep_selected = 2
	if Input.is_action_pressed("item3"):
		wep_selected = 3
	if Input.is_action_pressed("item4"):
		wep_selected = 4


func _process(delta):
	view_roll(delta)
	
	if Input.is_action_pressed("fire"):
		return

func _physics_process(delta):
	
	
	if ground_check.is_colliding():
		full_contact = true
		#print("is on floe")
	else:
		full_contact = false
		#print("is not on floe")
	
	if not is_on_floor():
		horiz_accel = air_accel
		grav_vec += Vector3.DOWN * gravity * delta
	elif is_on_floor() and full_contact:
		grav_vec = -get_floor_normal() * gravity
		horiz_accel = normal_accel
	else:
		grav_vec = -get_floor_normal()
		horiz_accel = normal_accel
	
	if Input.is_action_just_pressed("Jump") and full_contact:
		grav_vec = Vector3.UP * jump_force
	
	direction = Vector3()
	
	if Input.is_action_pressed("MoveForward"):
		direction -= transform.basis.z
	elif Input.is_action_pressed("MoveBackward"):
		direction += transform.basis.z
	if Input.is_action_pressed("MoveLeft"):
		direction -= transform.basis.x
	elif Input.is_action_pressed("MoveRight"):
		direction += transform.basis.x
	
	direction = direction.normalized()
	horiz_velocity = horiz_velocity.linear_interpolate(direction * speed, horiz_accel * delta)
	movement.z = horiz_velocity.z + grav_vec.z
	movement.x = horiz_velocity.x + grav_vec.x
	movement.y = grav_vec.y
	
	
	move_and_slide(movement, Vector3.UP)
	


func _unhandled_input(event: InputEvent) -> void:
		if Input.is_action_pressed("fire"):
			#if is_network_master() or !get_tree().network_peer:
				#get_node("Head/Holder/Weapon").rpc("shoot")
				get_node("Head/Holder/Weapon").shoot()
		
		if event is InputEventMouseMotion:
			rotate_y(deg2rad(-event.relative.x * MouseSens))
			Head.rotate_x(deg2rad(-event.relative.y * MouseSens))
			Head.rotation.x = clamp(Head.rotation.x, deg2rad(-89), deg2rad(89))
		
		if Input.is_action_pressed("action"):
				pass
			
func Damage(damage):
	health = health - damage
	
	if health <= 0:
		kill()


func kill():
	queue_free()
