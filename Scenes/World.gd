extends Node

func addPlayerToWorld(id) -> void:
	if !$Players.has_node(str(id)):
		$Players.add_child(NetworkLobby.instance_player(id))
