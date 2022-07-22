extends Spatial

var is_in_freecam = false
var transformoverride

onready var cam = $Camera

func _ready() -> void:
	pass



func _process(delta):
	global_transform = transformoverride if transformoverride else global_transform
	transformoverride = null


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not transformoverride:
		rotate_y(deg2rad(-event.relative.x * UserConfigs.aim_sens))
		rotate_x(deg2rad(-event.relative.y * UserConfigs.aim_sens))
		self.rotation.x = clamp(self.rotation.x, deg2rad(-89), deg2rad(89))

func attach_to_node(node):
	var camera_transform
	var camera_rotation
	camera_transform = node.global_transform.origin
	self.global_transform.origin = camera_transform
	pass
