extends Spatial

var noclip = false
var freelook = true
var transformoverride

var speed = 1.0
onready var cam : Camera = $Camera

func _process(delta):
	global_transform = transformoverride if transformoverride else global_transform
	if !transformoverride:
		if noclip:
			var dir : Vector3
			dir += (Input.get_action_strength('MoveRight') - Input.get_action_strength('MoveLeft')) * transform.basis.x
			dir += (Input.get_action_strength('Jump') - Input.get_action_strength('Crouch'))  * transform.basis.y
			dir += (Input.get_action_strength('MoveForward') - Input.get_action_strength('MoveBackward')) * -transform.basis.z
			global_transform.origin += dir * delta * (30 * speed if not Input.is_action_pressed('fire') else 80 * speed)
	transformoverride = null

func _unhandled_input(event: InputEvent) -> void:
	if transformoverride:
		return
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			speed *= 1 + get_process_delta_time()
			speed += 0.000001
		if event.button_index == BUTTON_WHEEL_DOWN:
			speed *= 1 - get_process_delta_time()
	if event is InputEventMouseMotion:
		if !transformoverride && !freelook:
			return
		rotate_y(deg2rad(-event.relative.x * UserConfigs.aim_sens))
		rotation.x -= event.relative.y * UserConfigs.aim_sens * get_process_delta_time()
		rotation.x = clamp(rotation.x, -PI/2, PI/2)
