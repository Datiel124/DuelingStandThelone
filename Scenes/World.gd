extends Node

func _ready() -> void:
	#check singleplayer

func addPlayerToWorld(id) -> void:
	if !$Players.has_node(str(id)):
		$Players.add_child(NetworkLobby.instance_player(id))
