extends Node

#Define option functions here

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
