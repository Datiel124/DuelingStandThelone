extends Spatial

var is_in_freecam = false
var transformoverride

onready var cam : Camera = $Camera

func _process(delta):
	global_transform = transformoverride if transformoverride else global_transform
	if !transformoverride:
		var dir : Vector3
		dir += (Input.get_action_strength('MoveRight') - Input.get_action_strength('MoveLeft')) * transform.basis.x
		dir += (Input.get_action_strength('Jump') - Input.get_action_strength('Crouch'))  * transform.basis.y
		dir += (Input.get_action_strength('MoveForward') - Input.get_action_strength('MoveBackward')) * -transform.basis.z
		
		global_transform.origin += dir * delta * (30 if not Input.is_action_pressed('fire') else 80)
		
	transformoverride = null

func _unhandled_input(event: InputEvent) -> void:
	if transformoverride:
		return
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * UserConfigs.aim_sens))
		rotation.x -= event.relative.y * UserConfigs.aim_sens * get_process_delta_time()
		rotation.x = clamp(rotation.x, -PI/2, PI/2)
