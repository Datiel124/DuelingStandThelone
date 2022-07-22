extends Label

func _ready() -> void:
	if UserConfigs.show_fps:
		show()
	else:
		hide()
		
func _process(delta):
	var _fps = str(Engine.get_frames_per_second())
	set_text("FPS: " + _fps)
