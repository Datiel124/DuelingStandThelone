extends Spatial

var mouse_movement_x
var mouse_movement_y
var sway_thres = 1
var sway_lerp = 5


export var sway_left : Vector3
export var sway_right : Vector3
export var sway_up : Vector3
export var sway_down : Vector3
export var sway_default : Vector3

func _unhandled_input(event: InputEvent) -> void:
	
	if event is InputEventMouseMotion:
		mouse_movement_x = event.relative.x
		mouse_movement_y = event.relative.y
		
func _process(delta):
	
	if mouse_movement_x != null:
		if mouse_movement_x > sway_thres:
			rotation = rotation.linear_interpolate(sway_left, sway_lerp*delta)
		elif mouse_movement_x < -sway_thres:
			rotation = rotation.linear_interpolate(sway_right, sway_lerp*delta)
		else:
			rotation = rotation.linear_interpolate(sway_default, sway_lerp*delta)
		 
	if mouse_movement_y != null:
		if mouse_movement_y > sway_thres:
			rotation = rotation.linear_interpolate(sway_up, sway_lerp*delta)
		elif mouse_movement_y < -sway_thres:
			rotation = rotation.linear_interpolate(sway_down, sway_lerp*delta)
		else:
			rotation = rotation.linear_interpolate(sway_default, sway_lerp*delta)
