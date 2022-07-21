extends Node

var custom_songs_enabled = false
var is_playing = false
var song_array_id = 0
var file_name
var file_extension
var file_path

var supported_types = ["mp3", "wav", "ogg"]

var randomize_playlist = true
onready var AudioPlayer = $AudioPlayer


func _ready():
	if custom_songs_enabled:
		if randomize_playlist == true:
			randomize_and_play()
	pass

func _process(delta):
	if Input.is_action_pressed("refresh_songs"):
		print("Refreshing music list..")
		UserConfigs.loadmusic()
		randomize_and_play()
		
	if custom_songs_enabled:
		pass

func playsong(index):
	var song = File.new()
	file_name = UserConfigs.songs[index].get_file()
	file_extension = UserConfigs.songs[index].get_extension()
	file_path = UserConfigs.songs[index]
	print("Now playing, " + file_name)
	
	if file_extension == "mp3":
		song.open(file_path, File.READ)
		var bytes = song.get_buffer(song.get_len())
		var audio_stream = AudioStreamMP3.new()
		audio_stream.data = bytes
		AudioPlayer.set_stream(audio_stream)
		AudioPlayer.play()
		song.close()
		pass

func randomize_and_play():
		randomize()
		if UserConfigs.songs.size() <= 0:
			return
		var random_song_index:int = randi() % UserConfigs.songs.size()
		print("Got music index " + str(random_song_index))
		playsong(random_song_index)
