extends Node

func _ready():
	update_activity()

func update_activity() -> void:
	var activity = Discord.Activity.new()
	activity.set_type(Discord.ActivityType.Playing)
	activity.set_state("In DEV Map")
	activity.set_details("Cooking it up..")

	var assets = activity.get_assets()
	assets.set_large_image("standthelonedev2")
	assets.set_large_text("Dev Map")
	assets.set_small_image("image_1")
	assets.set_small_text("Testing..")
	
	var timestamps = activity.get_timestamps()
	timestamps.set_start(OS.get_unix_time() + 100)
	timestamps.set_end(OS.get_unix_time() + 500)

	var result = yield(Discord.activity_manager.update_activity(activity), "result").result
	if result != Discord.Result.Ok:
		push_error(str(result))
