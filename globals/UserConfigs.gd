extends Node

var aim_sens : float = 0.13
var aim_ADS_mult : float = 0.8

var username : String = "player"

func _ready() -> void:
	loadconfigs()

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