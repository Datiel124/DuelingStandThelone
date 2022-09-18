extends Node

var aim_sens : float = 0.23
var aim_ADS_mult : float = 0.8
var custom_songs_enabled = true
var is_fullscreen = false
var is_vsync = false
var show_fps = false
var is_view_roll = true

#music saved 0 to 1 (linear2db)
var options_master_volume : float = 1.0
var options_game_volume : float = 1.0
var options_music_volume : float = 1.0
var options_ui_volume : float = 1.0


var username : String = "player"


func _ready() -> void:
	loadconfigs()


func _notification(what: int) -> void:
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		saveconfigs()


signal loaded_all_configs


func saveconfigs():
	print("Saving configs...")
	var start = Time.get_ticks_usec()
	var save = File.new()
	save.open("user://configs.save", File.WRITE)
#	save.store_line(to_json(variables))
	var properties = {}
	var thisScript : GDScript = get_script()
	for propertyInfo in thisScript.get_script_property_list():
		properties[propertyInfo.name] = get(propertyInfo.name)
#	print(properties)
	save.store_line(JSON.print(properties))
	save.close()
	print("Finished saving configs in " + str(Time.get_ticks_usec() - start) + "us.")


func loadconfigs():
	var save = File.new()
	if not save.file_exists("user://configs.save"):
		return
	save.open("user://configs.save", File.READ)
	while save.get_position() < save.get_len():
		var data = parse_json(save.get_line())
		for i in data.keys():
			set(i, data[i])
	print("loaded all configs")
	emit_signal('loaded_all_configs')


func add_music(dir : Directory, files:Array, directories: Array):
	print("Scanning for music..")
	var file_name = dir.get_next()
	while (file_name != ""):
		var file_path = dir.get_current_dir() + "/" + file_name
		if dir.current_is_dir():
			print("Found Directory %s. Ignoring." % file_path)
			#emit_signal("found_directory")
		else:
			files.append(file_path)
			print("Found file %s, Adding to array." % file_path)
			#emit_signal("found_song")
		file_name = dir.get_next()
		
	dir.list_dir_end()


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



