extends Spatial

var is_in_freecam = false
var transformoverride

onready var cam : Camera = $Camera

func _process(delta):
	global_transform = transformoverride if transformoverride else global_transform
	transformoverride = null

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not transformoverride:
		rotate_y(deg2rad(-event.relative.x * UserConfigs.aim_sens))
		rotation.x -= event.relative.y * UserConfigs.aim_sens * get_process_delta_time()
		rotation.x = clamp(rotation.x, -PI/2, PI/2)
