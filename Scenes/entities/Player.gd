extends KinematicBody

#Physics-related variables
var air_accel = 1
var normal_accel = 12
var speed = 13
var direction = Vector3()
var horiz_accel = 9
var gravity = 30
var jump_force = 10.5
var grav_vec = Vector3()
var full_contact = true
var horiz_velocity = Vector3()
var movement = Vector3()

#health
var health = 100 setget setHealth
func setHealth(newhealth):
	newhealth = clamp(newhealth, 0, 100)
	emit_signal('changeHealth', health, newhealth)
	health = newhealth
signal changeHealth(old, new)

#Weapon-selection references
var wep_selected

#References to nodes for simplification
onready var aimcast = $Head/Camera/AimCast
onready var ground_check = $FloorCheck
onready var Head = $Head
onready var camera = $Head/Camera
onready var Reach = $Head/Camera/Reach
onready var Hand = $Head/Holder
onready var anim_player = $AnimationPlayer


func _ready():
	setHealth(health)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func view_roll(delta):
	var rotation_speed : float = speed * delta
	var roll_amount : int = 2
	var angle : float = roll_amount * (int(Input.is_action_pressed("MoveRight")) + -int(Input.is_action_pressed("MoveLeft")))
	camera.rotation.z = lerp(camera.rotation.z, -deg2rad(angle), rotation_speed)

func _process(delta):
	view_roll(delta)

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
		if event.is_action_pressed("fire"):
			get_node("Head/Holder/Weapon").shoot()
		
		if event is InputEventMouseMotion:
			rotate_y(deg2rad(-event.relative.x * UserConfigs.aim_sens))
			Head.rotate_x(deg2rad(-event.relative.y * UserConfigs.aim_sens))
			Head.rotation.x = clamp(Head.rotation.x, deg2rad(-89), deg2rad(89))


func Damage(damage):
	setHealth(health - damage)
	if health <= 0:
		kill()


func kill():
	queue_free()
