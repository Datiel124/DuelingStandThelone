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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

