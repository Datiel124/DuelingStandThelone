extends Popup

func _on_Options_about_to_show() -> void:
	$AnimationPlayer.play('popup')
	pass # Replace with function body.


func _ready() -> void:
	#read audio settings saved and apply them to the sliders in options
	var opts = [UserConfigs.options_master_volume,
		UserConfigs.options_game_volume,
		UserConfigs.options_music_volume,
		UserConfigs.options_ui_volume]
	$'%MASTER-audio'.set_value(opts[0])
	$'%GAME-audio'.set_value(opts[1])
	$'%MUSIC-audio'.set_value(opts[2])
	$'%UI-audio'.set_value(opts[3])
	AudioServer.set_bus_volume_db(0, linear2db(opts[0]))
	AudioServer.set_bus_volume_db(3, linear2db(opts[1]))
	AudioServer.set_bus_volume_db(4, linear2db(opts[2]))
	AudioServer.set_bus_volume_db(5, linear2db(opts[3]))
	pass


func _on_exitbutton_pressed() -> void:
	$AnimationPlayer.play('close')
	pass # Replace with function body.


func _on_MASTERaudio_value_changed(value: float) -> void:
	UserConfigs.options_master_volume = value
	AudioServer.set_bus_volume_db(0, linear2db(value))
	pass # Replace with function body.


func _on_GAMEaudio_value_changed(value: float) -> void:
	UserConfigs.options_game_volume = value
	AudioServer.set_bus_volume_db(3, linear2db(value))
	pass # Replace with function body.


func _on_MUSICaudio_value_changed(value: float) -> void:
	UserConfigs.options_music_volume = value
	AudioServer.set_bus_volume_db(4, linear2db(value))
	pass # Replace with function body.


func _on_UIaudio_value_changed(value: float) -> void:
	UserConfigs.options_ui_volume = value
	AudioServer.set_bus_volume_db(5, linear2db(value))
	pass # Replace with function body. 
