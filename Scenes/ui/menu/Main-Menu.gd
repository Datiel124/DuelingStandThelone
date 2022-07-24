extends Node



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_TEST_ROOM_pressed() -> void:
	Network.createClient("192.168.0.0", 0)
	get_tree().change_scene("res://Scenes/levels/Map.tscn")
	pass # Replace with function body.
