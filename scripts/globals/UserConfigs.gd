extends Node

var aim_sens : float = 0.13
var aim_ADS_mult : float = 0.8
var custom_songs_enabled = true
var songs = []

var username : String = "player"

func _ready() -> void:
	loadconfigs()
	loadmusic()
	
func _notification(what: int) -> void:
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		saveconfigs()

signal loaded_all_configs

func saveconfigs():
	var save = File.new()
	save.open("user://configs.save", File.WRITE)
#	save.store_line(to_json(variables))
	var properties = {}
	var thisScript : GDScript = get_script()
	for propertyInfo in thisScript.get_script_property_list():
		properties[propertyInfo.name] = get(propertyInfo.name)
	print(properties)
	save.store_line(JSON.print(properties))
	save.close()

func loadconfigs():
	var save = File.new()
	if not save.file_exists("user://configs.save"):
		return
	save.open("user://configs.save", File.READ)
	while save.get_position() < save.get_len():
		var data = parse_json(save.get_line())
		for i in data.keys():
			set(i, data[i])
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

func loadmusic():
	#Define directory variable
	var directory = Directory.new()
	#Open user folder
	directory.open("user://")
	#If music directory doesn't exist, create it
	if not directory.dir_exists("user://music"):
		print("Couldn't find the music folder, creating..")
		directory.make_dir("music")
	#If it does exist, get all files in it and add it to an array
	else:
		if directory.open("user://music") == OK:
			print("Found Music Folder")
			var directories = []
			songs.clear()
			directory.list_dir_begin()
			add_music(directory, songs, directories)
			print("Added all the songs!")
			#emit_signal("got_songs")
		else:
			print("Couldn't open the music folder.. Must've not been made!")


