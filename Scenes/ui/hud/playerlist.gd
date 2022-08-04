extends Panel

func _process(delta: float) -> void:
	rect_size.y = $HBoxContainer.rect_size.y
	visible = Input.is_action_pressed('show_playerlist')

func _ready() -> void:
	visible = false
	NetworkLobby.connect('registeredPlayer', self, "_addPlayerToList")
	get_tree().connect('network_peer_disconnected', self, "_removePlayerFromList")

	#add players on startup
	if get_tree().is_network_server():
		var new_entry = $instancing/player_item.duplicate()
		new_entry.visible = true
		new_entry.name = "1"
		new_entry.get_node("name").text = NetworkLobby.my_info.username
		new_entry.get_node("score").text = str(0)
		$HBoxContainer.add_child(new_entry)
	for i in NetworkLobby.player_info:
		_addPlayerToList(i)

func _addPlayerToList(id : int) -> void:
	var new_face = NetworkLobby.player_info[id].username
	var new_entry = $instancing/player_item.duplicate()
	new_entry.visible = true
	new_entry.name = str(id)
	new_entry.get_node("name").text = new_face
	new_entry.get_node("score").text = str(0)
	$HBoxContainer.add_child(new_entry)

func _removePlayerFromList(id) -> void:
	$HBoxContainer.get_node(str(id)).queue_free()

func _setScore(id, amount) -> void:
	$HBoxContainer.get_node(str(id)).get_node("score").text = str(amount)
	
