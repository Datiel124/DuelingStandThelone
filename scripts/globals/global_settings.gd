extends Node

#Define option functions here

func instance_node_at_location(node: Object, location : Vector3) -> Object:
	var instance = instance_node(node)
	instance.transform.origin = location
	return instance

func instance_node(node: Object) -> Object:
	var node_to_instance = node
	return node_to_instance

#Fullscreen Toggle
func toggle_fullscreen(toggle):
	OS.window_fullscreen = toggle
	UserConfigs.is_fullscreen = toggle
	UserConfigs.saveconfigs()

#Vsync Toggle
func toggle_vsync(toggle):
	OS.vsync_enabled = toggle
	UserConfigs.is_vsync = toggle
	UserConfigs.saveconfigs()

#Show FPS Toggle
func toggle_showfps(toggle):
	UserConfigs.show_fps = toggle
	UserConfigs.saveconfigs()
