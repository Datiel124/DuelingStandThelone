extends Label

func _ready() -> void:
	#If the option to display FPS is on, then make the lable show up. Otherwise hide it.
	if UserConfigs.show_fps:
		show()
	else:
		hide()
		
func _process(delta):
	#Set FPS variable to game fps and set the text to the FPS Variable
	var _fps = str(Engine.get_frames_per_second())
	set_text("FPS: " + _fps)
