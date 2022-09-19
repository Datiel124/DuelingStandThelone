extends Node

var is_playing = false
var song_array_id = 0

var supported_types = ["mp3", "wav", "ogg"]

var randomize_playlist = true
onready var MusicPlayer : AudioStreamPlayer = $AudioPlayer
var songs = []

func _ready():
	randomize()
	MusicPlayer.set_bus("Music")
	yield(get_tree(), 'idle_frame')
	if UserConfigs.custom_songs_enabled:
		var thread = Thread.new()
		thread.start(self, 'scansongs')
		thread.wait_to_finish()
		if songs.size() > 0:
			setSong(randi()%songs.size())
	pass

func _process(delta):
	if Input.is_action_just_pressed("refresh_songs") && UserConfigs.custom_songs_enabled:
		print("Refreshing music list..")
		scansongs()

func scansongs():
	print("Beginning audio file scan...")
	var start = Time.get_ticks_msec()
	#Get the songs folder
	var songsfolder = "user://music/"
	#Scan the songs folder for song files
	var files = get_filelist(songsfolder)
	print(files)
	#Load each filepath, create AudioStreams, append to songs[] array
	for path in files:
	
		var file = File.new()
		
		if file.file_exists(path):
			
			file.open(path, File.READ)
			var audio_stream : AudioStream
			
			match path.get_extension():
				"mp3":
					audio_stream = AudioStreamMP3.new()
					audio_stream.data = file.get_buffer(file.get_len())
				"ogg":
					audio_stream = AudioStreamOGGVorbis.new()
					audio_stream.data = file.get_buffer(file.get_len())
				"wav":
					#wav is way too big dont use this
					pass
				"_":
					#other cases
					pass
			songs.append(audio_stream)
			file.close()
	print(songs)
	print("Finished scanning songs in " + str(Time.get_ticks_msec() - start) + "ms.")
	

func setSong(idx : int):
	MusicPlayer.set_stream(songs[idx])
	MusicPlayer.play()

func get_filelist(directory : String):
	var my_files : Array = []
	var dir := Directory.new()
	if dir.open(directory) != OK:
		printerr("Warning: could not open directory: ", directory)
		return []

	if dir.list_dir_begin(true, true) != OK:
		printerr("Warning: could not list contents of: ", directory)
		return []

	var file_name := dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			my_files += get_filelist(dir.get_current_dir() + "/" + file_name)
		else:
			my_files.append(dir.get_current_dir() + "/" + file_name)
		file_name = dir.get_next()
	return my_files
