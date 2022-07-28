extends Node



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#terminate the peer when going to the main menu
	Network.terminatePeer()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	pass # Replace with function body.

func _on_TEST_ROOM_pressed() -> void:
	#Create a client that doesn't join a server.
	Network.createClient("192.168.0.0", 0)
	get_tree().change_scene("res://Scenes/levels/Map.tscn")
	pass # Replace with function body.
