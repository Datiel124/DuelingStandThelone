extends Popup


#Video Settings
onready var showfps_toggle: CheckButton = $OptionCategories/Video/MarginContainer/VideoSettings/ShowFPSButton
onready var fullscreen_button: OptionButton = $OptionCategories/Video/MarginContainer/VideoSettings/DisplayButton
onready var vsyncbutton = $OptionCategories/Video/MarginContainer/VideoSettings/VsyncButton
onready var resolutions: OptionButton = $OptionCategories/Video/MarginContainer/VideoSettings/Resolutions
#Audio Settings
onready var master_slider: HSlider = $OptionCategories/Audio/MarginContainer/AudioSettings/MasterSlider
onready var music_slider: HSlider = $OptionCategories/Audio/MarginContainer/AudioSettings/MusicSlider
onready var sfx_slider: HSlider = $OptionCategories/Audio/MarginContainer/AudioSettings/SFXSlide
#Gameplay Settings
onready var fov_slider: HSlider = $OptionCategories/Gameplay/MarginContainer/GameplaySettings/FOVSlider

#Set UI buttons to match config
func _ready():
	fullscreen_button.select(1 if UserConfigs.is_fullscreen else 0)
	GlobalSettings.toggle_fullscreen(UserConfigs.is_fullscreen)
	vsyncbutton.pressed = UserConfigs.is_vsync
	showfps_toggle.pressed = UserConfigs.show_fps
	


#Fullscreen Toggle
func _on_Resolutions_item_selected(index):
	GlobalSettings.toggle_fullscreen(true if index == 1 else false)

#Vsync Toggle
func _on_VsyncButton_toggled(button_pressed):
	GlobalSettings.toggle_vsync(button_pressed)

#Show FPS Toggle
func _on_ShowFPSButton_toggled(button_pressed):
	GlobalSettings.toggle_showfps(button_pressed)
