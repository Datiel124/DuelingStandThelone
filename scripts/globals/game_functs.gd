extends Node

onready var main = get_tree().root.get_child(get_tree().root.get_child_count() - 1)

func instance_node_at_location(node: Object, location : Vector3) -> Object:
	var instance = instance_node(node)
	instance.transform.origin = location
	return instance

func instance_node(node: Object) -> Object:
	var node_to_instance = node
	return node_to_instance
	
func get_map_spawns():
	var spawns = get_node("/root/World/Level/spawnpoints")
	if spawns:
		return spawns.get_child(randi() % spawns.get_child_count()).global_transform
	else:
		return Transform(Basis.IDENTITY, Vector3(0.0, 10.0 + randf(), 0.0))

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
