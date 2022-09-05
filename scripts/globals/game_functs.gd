extends Node

onready var main = get_tree().root.get_child(get_tree().root.get_child_count() - 1)

func instance_node_at_location(node: Object, location : Vector3) -> Object:
	var instance = instance_node(node)
	instance.transform.origin = location
	return instance

func instance_node(node: Object) -> Object:
	var node_to_instance = node
	return node_to_instance

func get_map_spawns() -> Array:
	var spawns = get_node("/root/World/Level/spawnpoints")
	if spawns:
		return spawns.get_children()
	else:
		printerr("Current level is missing spawns. Creating spawnpoint at (0, 0)")
		var newspawn = Position3D.new()
		newspawn.global_transform = Transform.IDENTITY
		if get_node_or_null("root/World/Level/spawnpoints"):
			get_node("root/World/Level/spawnpoints").add_child(newspawn)
		else:
			printerr("Error - called get_map_spawns() while outside of a level.")
			return []
		return [newspawn]

func get_random_spawnpoint() -> Position3D:
	var list = get_map_spawns()
	return list[randi()%list.size()]

#scene-changing functions using the interactive resource loader
export var max_load_time = 30000;
signal load_progress_changed(new)
signal announce_goto()
signal error_goto()

func goto_scene(path : String, current_scene):
	get_tree().paused = true
	var loader = ResourceLoader.load_interactive(path)
	
	if loader == null:
		print("Resource loader unable to load resource at path")
		return
	
	var t = OS.get_ticks_msec()
	emit_signal('announce_goto')
	
	while OS.get_ticks_msec() - t < max_load_time:
		var err = loader.poll()
		if err == ERR_FILE_EOF:
			#loading complete
			var resource = loader.get_resource()
			get_tree().get_root().call_deferred('add_child', resource.instance())
			current_scene.queue_free()
			break
		elif err == OK:
			var progress = float(loader.get_stage()) / loader.get_stage_count()
			emit_signal('load_progress_changed', progress)
			yield(get_tree(),'idle_frame')
		else:
			emit_signal('error_goto')
			print("Error while loading file")
			break
	get_tree().paused = false
